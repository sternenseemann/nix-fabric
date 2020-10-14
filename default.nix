{ pkgs ? import <nixpkgs> {} }:

let
  supportPkgs = {
    buildMinecraftJar = pkgs.callPackage ./build-minecraft-jar.nix { };
    buildFabricModsDir = pkgs.callPackage ./build-fabric-mods-dir.nix { };
  };

  jars = import ./jars-1.16.3.nix {
    inherit (supportPkgs) buildMinecraftJar;
    inherit (pkgs) lib;
  };

in

supportPkgs // jars
