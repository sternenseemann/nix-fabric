# nix-fabric

Nix infrastructure for modded Minecraft using the [fabric](https://fabricmc.net) loader.

## fabric mods folder using nix

If you have a stateful (non declarative) local minecraft instance using
MultiMC or similar, you can build (and update) your `mods` folder using
`nix-fabric` like this:

```
$ nix-build \
    -E 'with (import ./. {}).fabricPackages_1_16_4; buildFabricModsDir [ litematica minihud tweakeroo carpet itemscroller ]' \
    --out-link ~/.local/share/multimc/instances/1.16.4/.minecraft/mods
…

$ ls ~/.local/share/multimc/instances/1.16.4/.minecraft/mods
carpet-1.4.18-2020-11-21.jar
itemscroller-0.15.0-dev-2020-11-03-183933.jar
litematica-0.0.0-dev-2020-11-03-184101.jar
malilib-0.10.0-dev.21+arne.2.jar
minihud-0.19.0-dev-2020-11-03-184029.jar
tweakeroo-0.10.0-dev-2020-11-22-174805.jar
```

Since `nix-fabric` can also keep track of runtime dependencies of
mods on other mods, `malilib` is installed although it is not
specified explicitly.

MultiMC won't list the mods, since they are symlinked, but fabric
will be happy to load them regardless.

## TODO

* Fabric modded Minecraft servers
* Other versions than 1.16.3 (feel free to contribute, I currently only use the latest version)
