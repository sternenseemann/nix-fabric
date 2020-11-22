{ lib, buildMinecraftJar, buildMasaMod }:

let
  minecraftVersion = "1.16.4";

  buildMasaMod' = buildMasaMod minecraftVersion;

in rec {
  server = buildMinecraftJar {
    pname = "server";
    version = minecraftVersion;
    url = "https://launcher.mojang.com/v1/objects/35139deedbd5182953cf1caa23835da59ca3d7cd/server.jar";
    hash = "sha256:01i5nd03sbnffbyni1fa6hsg5yll2h19vfrpcydlivx10gck0ka4";
    meta = {
      description = "Minecraft multiplayer server";
      license = lib.licenses.unfree;
    };
  };

  carpet =
    let
      version = "1.4.18";
      date = "2020-11-21";
      urldate = lib.substring 2 (builtins.stringLength date)
        (builtins.replaceStrings [ "-" ] [ "" ] date);
    in buildMinecraftJar {
      pname = "carpet";
      version = "${version}-${date}";
      url = "https://github.com/gnembon/fabric-carpet/releases/download/v1.4-homebound/fabric-carpet-${minecraftVersion}-${version}+v${urldate}.jar";
      hash = "sha256:1vzcwh4n6gpdb76z8w4yrkddwvz72fjvbxkf3cbncvqvmv7dvpzp";
      meta = {
        description = "Carpet Mod is a mod for vanilla Minecraft that allows you to take full control of what matters from a technical perspective of the game";
        license = lib.licenses.mit;
        homepage = "https://github.com/gnembon/fabric-carpet";
      };
  };

  # carpet-extra = { };

  itemscroller = buildMasaMod' {
    pname = "itemscroller";
    version = "0.15.0-dev";
    date = "2020-11-03";
    time = "18:39:33";
    hash = "sha256:0g2jxg8rnns1x94j46vh2xj6mmz054gms709fqkkhvd6pdb0rnim";
    dependencies = [ malilib ];
    meta = {
      description = "Tiny Minecraft mod that allows moving items by scrolling over the inventory slots";
      license = lib.licenses.gpl3Only;
    };
  };

  litematica = buildMasaMod' {
    pname = "litematica";
    version = "0.0.0-dev";
    date = "2020-11-03";
    time = "18:41:01";
    hash = "sha256:1v2w587py2f7pyh0cy84mv3akipmqx2dn29540cfprzhfdn60x4a";
    dependencies = [ malilib ];
    meta = {
      description = "Litematica is a client-side schematic mod for Minecraft";
    };
  };

  malilib = buildMasaMod' {
    pname = "malilib";
    version = "0.10.0-dev.21+arne.2";
    hash = "sha256:1h629bmp4dr9f0vcvlxdlji3cjrp06qdasy5mgwdvqg33gazg3qz";
    meta = {
      description = "malilib is a library mod used by masa's LiteLoader mods";
      license = lib.licenses.gpl3Only;
    };
  };

  minihud = buildMasaMod' {
    pname = "minihud";
    version = "0.19.0-dev";
    date = "2020-11-03";
    time = "18:40:29";
    hash = "sha256:1dngxwjvqag7kf14vqj2rjdwvqkdkkw649k5zrgvq6clrbwn1jnr";
    dependencies = [ malilib ];
    meta = {
      description = "MiniHUD is a client-side information and overlay rendering mod for Minecraft";
    };
  };

  tweakeroo = buildMasaMod' {
    pname = "tweakeroo";
    version = "0.10.0-dev";
    date = "2020-11-22";
    time = "17:48:05";
    hash = "sha256:1y7f8apis7kd05c12wfx5c0bxj4q8nnc80ml0rpjhl7n3ydikxml";
    dependencies = [ malilib ];
    meta = {
      description = "Tweakeroo adds a selection of miscellaneous, configurable, client-side tweaks to the game";
      license = lib.licenses.gpl3Only;
    };
  };
}
