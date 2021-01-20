{ lib, fetchMinecraftJar }:

minecraftVersion:

{ date ? ""
, time ? ""
, meta ? {}
, version
, pname
, ...
}@args:

let
  urldate = builtins.replaceStrings [ "-" ] [ "" ] date;
  urltime = builtins.replaceStrings [ ":" ] [ "" ] time;
  urlVersion =
    if time == "" || date == ""
    then version
    else "${version}.${urldate}.${urltime}";
  versionString =
    if time == "" || date == ""
    then version
    else "${version}-${date}-${urltime}";

in fetchMinecraftJar ({
  version = versionString;
  url = "https://masa.dy.fi/tmp/minecraft/mods/${pname}/${pname}-fabric-${minecraftVersion}-${urlVersion}.jar";
  meta = {
    homepage = "https://github.com/maruohon/${pname}";
    license = lib.licenses.lgpl3Only;
  } // meta;
} // builtins.removeAttrs args [ "date" "time" "meta" "version" ])

