{ stdenv, fetchurl }:

{ url
, hash
, pname
, version
, meta ? {}
, dependencies ? []
, ...
}@args:

fetchurl ({
  name = "${pname}-${version}.jar";
  passthru = {
    inherit dependencies;
  };
} // builtins.removeAttrs args [ "dependencies" "pname" "version" ])

