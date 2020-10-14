{ lib, runCommandLocal }:

mods:

let
  setMod = m: { "${m.name}" = m; };
  allMods = lib.mapAttrsToList (n: m: m)
    (builtins.foldl'
      (s: m: s // (setMod m) // (builtins.foldl' (s: e: s // e) {}
        (builtins.map setMod m.passthru.dependencies)))
      {} mods);
  copyMod = drv: ''
    install -m644 ${drv} $out/${drv.name}
  '';
in

runCommandLocal "mods" {} ''
  mkdir -p "$out"
  ${lib.concatMapStringsSep "\n" copyMod allMods}
''
