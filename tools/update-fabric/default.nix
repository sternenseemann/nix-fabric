{ buildLispPackage, writeText, makeWrapper
, cl-json, drakma, alexandria, jq
}:

let
  baseName = "update-fabric";

  writeExecutable = name: writeText "write-executable.lisp" ''
    (require :uiop)
    (require :${name})

    (let ((out (merge-pathnames "bin/${name}"
                                (make-pathname :directory (uiop:getenvp "out")))))
      (save-lisp-and-die out
                         :executable t
                         :toplevel (function ${name}:main)
                         :purify t))
  '';
in

buildLispPackage {
  inherit baseName;
  version = "unstable";

  buildInputs = [
    cl-json drakma alexandria jq makeWrapper
  ];
  deps = [];

  buildSystems = [ "update-fabric" ];

  src = builtins.path {
    path = ./.;
    name = "update-fabric-source";
  };

  overrides = _: {
    postInstall = ''
      $out/bin/${baseName}-lisp-launcher.sh \
        --script ${writeExecutable baseName}

      wrapProgram "$out/bin/${baseName}" \
        --prefix PATH ":" "${jq}/bin"
    '';
  };

  description = "Simple tool to update version info of the fabric mod loader";
}
