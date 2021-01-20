(defpackage :update-fabric
  (:use :cl :uiop)
  (:import-from :drakma :http-request)
  (:import-from :alexandria :define-constant)
  (:import-from :cl-json :encode-json :decode-json)
  (:export :main :latest-fabric-installer-set
           :stable-loaders :loader-meta :loader-profile
           :library-set :nix-jar-set :known-minecraft-versions
           :parse-maven-identifier :maven-url
           :loader-dependency-set :*fake-hash*))

(declaim (optimize (safety 3)))

(in-package :update-fabric)

(define-constant
  +meta-api+
  "https://meta.fabricmc.net/v2"
  :test #'equal)

(define-constant
  +fabric-maven+
  "https://maven.fabricmc.net/"
  :test #'equal)

(defparameter *fake-hash* nil
  "Wether to call nix-prefetch-url or just emit lib.fakeSha256")

(defun assocc (key alist)
  "Assoc wrapper which supports nested alists (via a list of keys)
  and always returns the value (i. e. the cdr of the return value
  of assoc)."
  ; TODO(sterni): support :test
  (cond
    ((null alist) nil)
    ((typep key 'list)
     (if (null key)
       alist
       (assocc (cdr key)
               (cdr (assoc (car key) alist)))))
    (t (cdr (assoc key alist)))))

(defun known-minecraft-versions (top-level)
  "Read the data file of nix-fabric describing which minecraft
  versions are currently supported and return them"
  (check-type top-level pathname)
  (let ((path (merge-pathnames "data/minecraft-versions.json" top-level)))
    (with-open-file (s path :direction :input)
      (decode-json s))))

(defun endpoint (e)
  "Return full url to a meta api endpoint. May not include
  version and must start with a slash."
  (concatenate 'string +meta-api+ e))

(defun stable-loaders ()
  "Filters the /v2/versions/loader endpoint for stable releases"
  (remove-if-not
    (lambda (x) (cdr (assoc :stable x)))
    (decode-json
      (http-request #.'(endpoint "/versions/loader")
                    :want-stream t))))

(defun loader-meta (mc-version loader-version)
  "/v2/versions/loader/:minecraft-version/:loader-version"
  (check-type loader-version string)
  (check-type mc-version string)
  (let ((url #.'(endpoint (format nil "/versions/loader/~A/~A"
                                  mc-version loader-version))))
    (decode-json (http-request url :want-stream t))))

(defun loader-profile (mc-version loader-version)
  "/v2/versions/loader/:minecraft-version/:loader-version/profile/json"
  (check-type loader-version string)
  (check-type mc-version string)
  (let ((url #.'(endpoint (format nil "/versions/loader/~A/~A/profile/json"
                                  mc-version loader-version))))
    (decode-json (http-request url :want-stream t))))

(defun parse-maven-identifier (maven)
  "Given a maven identifier return its components as two
  multiple values: The path as a list of its components
  and the version as a second value"
  ; TODO(sterni): find out what the separator field means
  (check-type maven string)
  (let ((components (uiop:split-string maven :separator ":")))
    (unless (< 3 (length components))
      (values (append (uiop:split-string (car components) :separator ".")
                      (list (cadr components)))
              (caddr components)))))

(defun maven-url (base identifier version)
  "Given the base url of a maven, its identifier as a list of path
  components and its version, return url to the described .jar"
  (let* ((name (car (last identifier)))
         (path (reduce (lambda (x y)
                         (uiop:strcat x #\/ y)) identifier))
         (file (format nil "/~A/~A-~A.jar" version name version)))
    (uiop:strcat base path file)))

(defun nix-prefetch-url (url &optional (hash-type "sha256"))
  "Call nix-prefetch-url(1) from CL"
  (uiop:stripln
    (with-output-to-string (*standard-output*)
      (uiop:run-program
        (uiop:escape-command
          (list "nix-prefetch-url" "--type" hash-type url))
        :output *standard-output*
        :force-shell t))))

(defun nix-jar-set (base id &optional (override-url nil))
  "Given a maven instance and a maven identifier as a string,
  return a JSON object which can be used as an argument set
  for fetchMavenJar. If override-url is given, use given url
  instead of inferring it using maven-url."
  (multiple-value-bind (path version) (parse-maven-identifier id)
    (let* ((url (or override-url (maven-url base path version)))
           (hash (if *fake-hash*
                   "0000000000000000000000000000000000000000000000000000"
                   (nix-prefetch-url url))))
      `((:url . ,url)
        (:sha256 . ,hash)
        (:class-path . ,path)
        (:version . ,version)))))

(defun library-set (obj)
  "Calls nix-jar-set with the information from
  a library object of the fabricmc meta API."
  (check-type obj list)
  (let ((id (assocc :name obj))
        (base (assocc :url obj)))
    (when (and id base)
      (nix-jar-set base id))))

(defun default-library-object (maven-id)
  "Return an assoc list which can be used as an input to
  library-set for a maven id which is hosted of +fabric-maven+"
  `((:name . ,maven-id)
    (:url . ,+fabric-maven+)))

(defun loader-dependency-set (minecraft-version loader-version)
  "Given a minecraft and fabric-loader version, build a hash
  table from maven identifier to a JSON object which may be
  used as the fetchMavenJar argument containing all dependencies
  of the specified fabric-loader version."
  (check-type minecraft-version string)
  (check-type loader-version string)
  (let* ((meta (loader-meta minecraft-version loader-version))
         (loader-maven (assocc '(:loader :maven) meta))
         (inter-maven (assocc '(:intermediate :maven) meta))
         ; dependencies are in part specified multiple times
         ; so we use a hash table with their maven identiefiers
         ; as keys to automatically deduplicate them
         (output-set (make-hash-table :test #'equal)))
    (loop
      for lib
      in (append (list (default-library-object loader-maven))
                 (list (default-library-object inter-maven))
                 (assocc '(:launcher-meta :libraries :common) meta)
                 (assocc '(:launcher-meta :libraries :client) meta)
                 (assocc '(:launcher-meta :libraries :server) meta))
      for key = (assocc :name lib)
      when (and lib key)
      do (setf (gethash key output-set) (library-set lib))
      finally (return output-set))))

(defun latest-fabric-installer-set ()
  "Get the latest fabric-installer meta data, resolve its hash
  and generate a JSON object which can be used as an input set
  to fetchMavenJar"
  (let* ((url #.'(endpoint "/versions/installer"))
         (obj (car (decode-json
                     (http-request url :want-stream t)))))
    (when obj
      (nix-jar-set nil (assocc :maven obj) (assocc :url obj)))))

(defun encode-json-pretty (out-file data)
  "Use cl-json to encode data to JSON and render
  it pretty-printed to out-file using jq"
  (let ((jq (uiop:launch-program
              (uiop:escape-command '("jq" "-M"))
              :force-shell t :error-output nil
              :output out-file :input :stream)))
    (encode-json data (uiop:process-info-input jq))
    (uiop:close-streams jq)
    (let ((exit (uiop:wait-process jq)))
      (unless (= 0 exit)
        (error (format nil "jq non-zero exit: ~D" exit))))))

(defun main ()
  ; without this uiop somehow caches /build/ as TMPDIR
  ; from build time when using buildLispPackage‽
  (uiop:setup-temporary-directory)
  (let* ((top-level (pathname (or (car (uiop:command-line-arguments)) ".")))
         (lock (merge-pathnames "data/fabric-lock.json" top-level))
         (loader (car (stable-loaders)))
         (loader-version (assocc :version loader))
         (minecraft-versions (known-minecraft-versions top-level))
         (loader-dependencies (make-hash-table :test #'equal))
         (installer-set (latest-fabric-installer-set)))
    (format t "Latest stable installer: ~A~%" (assocc :version installer-set))
    (format t "Latest stable loader: ~A~%" loader-version)
    ; this should never clash with any dependency of fabric-loader
    ; and is usefule for nix to conveniently find out the used version
    (loop
      for v in minecraft-versions
      do (format t "Getting dependencies for Minecraft ~A~%" v)
      do (setf (gethash v loader-dependencies)
               (loader-dependency-set v loader-version)))
    (format t "Writing locked fabric jars to ~A~%" lock)
    (encode-json-pretty lock
      `(("fabric-loader" . ((:version . ,loader-version)
                            (:dependencies . ,loader-dependencies)))
        ("fabric-installer" . ,installer-set)))))
