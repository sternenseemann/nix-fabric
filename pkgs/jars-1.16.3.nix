{ self, lib }:

with self;

{
  server = fetchMinecraftJar {
    pname = "server";
    version = minecraftVersion;
    url = "https://launcher.mojang.com/v1/objects/f02f4473dbf152c23d7d484952121db0b36698cb/server.jar";
    hash = "sha256:0nxdyw23037cr9cfcsfq1cvpy75am5dzmbgvvh3fq6h89kkm1r1j";
    meta = {
      description = "Minecraft multiplayer server";
      license = lib.licenses.unfree;
    };
  };

  carpet =
    let
      version = "1.4.12";
      date = "2020-10-01";
      urldate = lib.substring 2 (builtins.stringLength date)
        (builtins.replaceStrings [ "-" ] [ "" ] date);
    in fetchMinecraftJar {
      pname = "carpet";
      version = "${version}-${date}";
      url = "https://github.com/gnembon/fabric-carpet/releases/download/v1.4-homebound/fabric-carpet-${minecraftVersion}-${version}+v${urldate}.jar";
      hash = "sha256:1cvb753b1y59w3d8h2mkp4254w0ckrmwfa42znh0f6qz6jpd14kq";
      meta = {
        description = "Carpet Mod is a mod for vanilla Minecraft that allows you to take full control of what matters from a technical perspective of the game";
        license = lib.licenses.mit;
        homepage = "https://github.com/gnembon/fabric-carpet";
      };
  };

  # carpet-extra = { };

  itemscroller = fetchMasaMod {
    pname = "itemscroller";
    version = "0.15.0-dev";
    date = "2020-09-12";
    time = "22:18:05";
    hash = "sha256:0zgj9krxs5dxdb5w8jv7ryjld06z5hb81rpaszlnh85l021n52i7";
    dependencies = [ malilib ];
    meta = {
      description = "Tiny Minecraft mod that allows moving items by scrolling over the inventory slots";
      license = lib.licenses.gpl3Only;
    };
  };

  litematica = fetchMasaMod {
    pname = "litematica";
    version = "0.0.0-dev";
    date = "2020-09-20";
    time = "16:16:40";
    hash = "sha256:02d8bm2c6f0rwagxlvgcc1k109mw0a5yrala4hw54qx7j7h7as12";
    dependencies = [ malilib ];
    meta = {
      description = "Litematica is a client-side schematic mod for Minecraft";
    };
  };

  malilib = fetchMasaMod {
    pname = "malilib";
    version = "0.10.0-dev.21+arne.1";
    hash = "sha256:080jszf61ac07yxcrxgzix4cy1mrvqahbcipny534p13cpz0qrbc";
    meta = {
      description = "malilib is a library mod used by masa's LiteLoader mods";
      license = lib.licenses.gpl3Only;
    };
  };

  minihud = fetchMasaMod {
    pname = "minihud";
    version = "0.19.0-dev";
    date = "2020-10-27";
    time = "14:54:41";
    hash = "sha256:0krmvrb82kgj5vq09dxcrv0jw5xza92pk0xb54j6i8dj7bzmddix";
    dependencies = [ malilib ];
    meta = {
      description = "MiniHUD is a client-side information and overlay rendering mod for Minecraft";
    };
  };

  tweakeroo = fetchMasaMod {
    pname = "tweakeroo";
    version = "0.10.0-dev";
    date = "2020-10-04";
    time = "19:18:11";
    hash = "sha256:18b8qjza10ylsig6ca1kwn4n98dwlvb5ns2rgar859acvnk75h51";
    dependencies = [ malilib ];
    meta = {
      description = "Tweakeroo adds a selection of miscellaneous, configurable, client-side tweaks to the game";
      license = lib.licenses.gpl3Only;
    };
  };
}
