{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) fix nameValuePair;
  inherit (builtins) readFile fromJSON map listToAttrs replaceStrings;

  common = self: {
    # from nixpkgs
    jre = pkgs.jre8_headless;

    inherit (pkgs) lib;

    # set management
    callPackage = self.lib.callPackageWith ({
      inherit (pkgs) stdenv fetchurl runCommandLocal;
    } // self);

    # standard build support
    fetchMinecraftJar = self.callPackage ./build-support/fetch-minecraft-jar.nix { };

    fetchMavenJar = self.callPackage ./build-support/fetch-maven-jar.nix { };
    buildFabricModsDir = self.callPackage ./build-support/build-fabric-mods-dir.nix { };

    fetchMasaMod =
      self.callPackage ./build-support/fetch-masa-mod.nix { } self.minecraftVersion;
  } // import ./pkgs/jars-common.nix self;

  minecraftVersionSet = minecraftVersion: jars:
    fix (self: common self // {
      inherit minecraftVersion;
    } // import jars self);

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
