{ stdenv, fetchurl }:

{ url
, hash
, pname
, version
, meta ? {}
, dontUnpack ? true
, sourcePath ? ""
, dependencies ? []
}:

assert !dontUnpack -> sourcePath != "";

stdenv.mkDerivation rec {
  inherit version;
  name = "${pname}-${version}.jar";

  src = fetchurl {
    inherit url hash;
  };

  inherit dontUnpack;

  installPhase =
    if dontUnpack
    then "install -m644 $src $out"
    else "install -m644 ${sourcePath} $out";

  inherit meta;

  passthru = {
    inherit dependencies;
  };
}
