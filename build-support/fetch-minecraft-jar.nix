{ stdenv, fetchurl }:

{ url
, pname
, version
, meta ? {}
, dependencies ? []
, passthru ? {}
, ...
}@args:

fetchurl ({
  name = "${pname}-${version}.jar";
  passthru = {
    inherit version;
    inherit dependencies;
  } // passthru;
} // builtins.removeAttrs args [ "dependencies" "pname" "version" "passthru" ])

