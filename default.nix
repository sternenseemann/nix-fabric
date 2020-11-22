{ pkgs ? import <nixpkgs> {} }:

let
  common = rec {
    callPackage = pkgs.lib.callPackageWith (pkgs // common);

    buildMinecraftJar = callPackage ./build-minecraft-jar.nix { };

    buildMasaMod = callPackage ./build-masa-mod.nix { };

    inherit (callPackage ./jars-common.nix { }) fabric-installer;
  };

  minecraftVersionSet = jars:
    let
      newSet = common // (common.callPackage jars {}) // rec {
        callPackage = pkgs.lib.callPackageWith (pkgs // newSet);
        buildFabricModsDir = callPackage ./build-fabric-mods-dir.nix {
          fabricPackages = newSet;
        };
      };
    in newSet;

in rec {
  fabricPackages = fabricPackages_1_16_4;
  fabricPackages_1_16_3 = minecraftVersionSet ./jars-1.16.3.nix;
  fabricPackages_1_16_4 = minecraftVersionSet ./jars-1.16.4.nix;
}
