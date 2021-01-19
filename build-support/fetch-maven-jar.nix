{ lib, fetchMinecraftJar }:

{ classPath
, version
, mavenUrl ? "https://maven.fabricmc.net"
, ...
}@args:

assert (lib.assertMsg (builtins.length classPath > 0)
                      "classPath may not be []");

let
  pname = lib.last classPath;
  args' = builtins.removeAttrs args [ "classPath" "mavenUrl" ];
in

fetchMinecraftJar ({
  inherit pname;
  url = "${mavenUrl}${lib.concatStringsSep "/" classPath}/${version}/${pname}-${version}.jar";
} // args')
