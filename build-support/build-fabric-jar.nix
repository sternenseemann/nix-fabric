{ buildMinecraftJar }:

{ pname
, version
, ...
}@args:

buildMinecraftJar ({
  url = "https://maven.fabricmc.net/net/fabricmc/${pname}/${version}/${pname}-${version}.jar";
} // args)
