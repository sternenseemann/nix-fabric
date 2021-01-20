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

(defparameter *fake-hash* nil)

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

(defun endpoint (e)
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
  ; TODO(sterni): find out what the separator field means
  (check-type maven string)
  (let ((components (uiop:split-string maven :separator ":")))
    (unless (< 3 (length components))
      (values (append (uiop:split-string (car components) :separator ".")
                      (list (cadr components)))
              (caddr components)))))

(defun maven-url (base identifier version)
  (let* ((name (car (last identifier)))
         (path (reduce (lambda (x y)
                         (uiop:strcat x #\/ y)) identifier))
         (file (format nil "/~A/~A-~A.jar" version name version)))
    (uiop:strcat base path file)))

(defun nix-prefetch-url (url &optional (hash-type "sha256"))
  (uiop:stripln
    (with-output-to-string (*standard-output*)
      (uiop:run-program
        (uiop:escape-command
          (list "nix-prefetch-url" "--type" hash-type url))
        :output *standard-output*
        :force-shell t))))

(defun nix-jar-set (base id &optional (override-url nil))
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
  (check-type obj list)
  (let ((id (assocc :name obj))
        (base (assocc :url obj)))
    (when (and id base)
      (nix-jar-set base id))))

(defun known-minecraft-versions (top-level)
  (check-type top-level pathname)
  (let ((path (merge-pathnames "data/minecraft-versions.json" top-level)))
    (with-open-file (s path :direction :input)
      (decode-json s))))

(defun default-library-object (maven-id)
  `((:name . ,maven-id)
    (:url . ,+fabric-maven+)))

(defun loader-dependency-set (minecraft-version loader-version)
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
  (let* ((url #.'(endpoint "/versions/installer"))
         (obj (car (decode-json
                     (http-request url :want-stream t)))))
    (when obj
      (nix-jar-set nil (assocc :maven obj) (assocc :url obj)))))

(defun main ()
  ; without this uiop somehow caches /build/ as TMPDIR
  ; from build time when using buildLispPackage‽
  (uiop:setup-temporary-directory)
  (let* ((top-level (pathname (or (car (uiop:command-line-arguments)) ".")))
         (out (merge-pathnames "data/fabric-lock.json" top-level))
         (loader-version (cdr (assoc :version (car (stable-loaders)))))
         (minecraft-versions (known-minecraft-versions top-level))
         (loader-sets (make-hash-table :test #'equal))
         (installer-set (latest-fabric-installer-set)))
    (format t "Latest stable installer: ~A~%" (assocc :version installer-set))
    (format t "Latest stable loader: ~A~%" loader-version)
    ; this should never clash with any dependency of fabric-loader
    ; and is usefule for nix to conveniently find out the used version
    (setf (gethash :version loader-sets) loader-version)
    (loop
      for v in minecraft-versions
      do (format t "Getting dependencies for Minecraft ~A~%" v)
      do (setf (gethash v loader-sets)
               (loader-dependency-set v loader-version)))
    (format t "Writing locked fabric jars to ~A~%" out)
    ; use jq for pretty printing
    (let ((jq (uiop:launch-program
                (uiop:escape-command '("jq" "-M"))
                :force-shell t :error-output nil
                :output out :input :stream)))
      (encode-json
        `(("fabric-loader" . ,loader-sets)
          ("fabric-installer" . ((:generic . ,installer-set))))
        (uiop:process-info-input jq))
      (uiop:close-streams jq)
      ; exit with jq's exit status
      (let ((exit (uiop:wait-process jq)))
        (unless (= 0 exit)
          (format t "Error: jq exited with ~D" exit)
          (uiop:quit exit))))))
