{ stdenv, fetchurl }:

{ url
, pname
, version
, meta ? {}
, dependencies ? []
, ...
}@args:

fetchurl ({
  name = "${pname}-${version}.jar";
  passthru = {
    inherit version;
    inherit dependencies;
  };
} // builtins.removeAttrs args [ "dependencies" "pname" "version" ])

