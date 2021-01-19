self:

with self;

{
  fabric-installer = buildMinecraftJar rec {
    pname = "fabric-installer";
    version = "0.6.1.51";
    url = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${version}/fabric-installer-${version}.jar";
    hash = "sha256:0cima0n3b37qha9a16kcvjnx9mg231v5wdg1063gxnq3vrxlcw23";
    meta = {
      homepage = "https://github.com/FabricMC/fabric-installer";
      description = "Installer for the fabric Minecraft mod loader";
      license = lib.licenses.asl20;
    };
  };
}
