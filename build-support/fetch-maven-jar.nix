{ lib, fetchMinecraftJar }:

{ classPath
, version
, mavenUrl ? "https://maven.fabricmc.net"
, passthru ? {}
, ...
}@args:

assert (lib.assertMsg (builtins.length classPath > 0)
                      "classPath may not be []");

let
  pname = lib.last classPath;
  args' = builtins.removeAttrs args [ "classPath" "mavenUrl" "passthru" ];
in

fetchMinecraftJar ({
  inherit pname;
  url = "${mavenUrl}${lib.concatStringsSep "/" classPath}/${version}/${pname}-${version}.jar";
  passthru = {
    inherit classPath;
  } // passthru;
} // args')
