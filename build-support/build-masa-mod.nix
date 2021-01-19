{ lib, buildMinecraftJar }:

minecraftVersion:

{ pname, version, date ? "", time ? ""
, hash, meta ? {}, dependencies ? []
}:

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

in buildMinecraftJar {
  inherit pname hash dependencies;
  version = versionString;
  url = "https://masa.dy.fi/tmp/minecraft/mods/${pname}/${pname}-fabric-${minecraftVersion}-${urlVersion}.jar";
  meta = {
    homepage = "https://github.com/maruohon/${pname}";
    license = lib.licenses.lgpl3Only;
  } // meta;
}

