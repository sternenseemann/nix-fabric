{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.lib) fix;

  common = self: {
    buildMinecraftJar = self.callPackage ./build-support/build-minecraft-jar.nix { };

    buildFabricJar = self.callPackage ./build-support/build-fabric-jar.nix { };
  } // import ./pkgs/jars-common.nix self;

  minecraftVersionSet = minecraftVersion: jars:
    fix (self: common self // {
      inherit minecraftVersion;

      inherit (pkgs) lib;

      callPackage = self.lib.callPackageWith ({
        inherit (pkgs) stdenv fetchurl runCommandLocal;
      } // self);

      buildFabricModsDir = self.callPackage ./build-support/build-fabric-mods-dir.nix { };

      buildMasaMod =
        self.callPackage ./build-support/build-masa-mod.nix { } self.minecraftVersion;
    } // import jars self);

in rec {
  fabricPackages = fabricPackages_1_16_4;
  fabricPackages_1_16_3 = minecraftVersionSet "1.16.3" ./pkgs/jars-1.16.3.nix;
  fabricPackages_1_16_4 = minecraftVersionSet "1.16.4" ./pkgs/jars-1.16.4.nix;
}
