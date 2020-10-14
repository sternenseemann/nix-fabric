# nix-fabric

Nix infrastructure for modded Minecraft using the [fabric](https://fabricmc.net) loader.

## fabric mods folder using nix

If you have a stateful (non declarative) local minecraft instance using
MultiMC or similar, you can build (and update) your `mods` folder using
`nix-fabric` like this:

```
$ nix-build \
    -E 'with (import ./. {}); fabricPackages_1_16_3.buildFabricModsDir (p: with p; [ litematica minihud tweakeroo carpet itemscroller ])' \
    --out-link ~/.multimc/instances/1.16.3/.minecraft/mods
…

$ ls ~/.multimc/instances/1.15.1/.minecraft/mods/
carpet-1.4.12-2020-10-01.jar
itemscroller-0.15.0-dev-2020-09-12-221805.jar
litematica-0.0.0-dev-2020-09-20-161640.jar
malilib-0.10.0-dev.21+arne.1.jar
minihud-0.19.0-dev-2020-09-28-220110.jar
tweakeroo-0.10.0-dev-2020-10-04-191811.jar
```

Since `nix-fabric` can also keep track of runtime dependencies of
mods on other mods, `malilib` is installed although it is not
specified explicitly.

MultiMC won't list the mods, since they are symlinked, but fabric
will be happy to load them regardless.

## TODO

* Fabric modded Minecraft servers
* Other versions than 1.16.3 (feel free to contribute, I currently only use the latest version)
