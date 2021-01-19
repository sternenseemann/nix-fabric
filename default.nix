{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) fix;

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

in rec {
  fabricPackages = fabricPackages_1_16_4;
  fabricPackages_1_16_3 = minecraftVersionSet "1.16.3" ./pkgs/jars-1.16.3.nix;
  fabricPackages_1_16_4 = minecraftVersionSet "1.16.4" ./pkgs/jars-1.16.4.nix;
}
