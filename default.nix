{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) fix nameValuePair;
  inherit (builtins) readFile fromJSON map listToAttrs replaceStrings;

  fabricLock = fromJSON (readFile ./data/fabric-lock.json);

  common = self: {
    # from nixpkgs
    jre = pkgs.jre8_headless;

    # set management
    callPackage = pkgs.lib.callPackageWith ({
      inherit (pkgs) stdenv lib fetchurl runCommandLocal;
    } // self);

    # standard build support
    fetchMinecraftJar = self.callPackage ./build-support/fetch-minecraft-jar.nix { };

    fetchMavenJar = self.callPackage ./build-support/fetch-maven-jar.nix { };
    buildFabricModsDir = self.callPackage ./build-support/build-fabric-mods-dir.nix { };

    fetchMasaMod =
      self.callPackage ./build-support/fetch-masa-mod.nix { } self.minecraftVersion;

    # version agnostic jars

    fabric-installer = self.fetchMavenJar fabricLock.fabric-installer.generic;
  };

  minecraftVersionSet = minecraftVersion: jars:
    fix (self: common self // {
      inherit minecraftVersion;
    } // import jars { inherit self; inherit (pkgs) lib; });

  knownVersions = fromJSON (readFile ./data/minecraft-versions.json);

  knownSets =
    map (v:
      let
        name = "fabricPackages_${replaceStrings [ "." ] [ "_" ] v}";
        path = "${./pkgs}/jars-${v}.nix";
      in
        nameValuePair name (minecraftVersionSet v path))
      knownVersions;
in

fix (self: {
  fabricPackages = self.fabricPackages_1_16_4;
} // listToAttrs knownSets)
