# MacOS config (nix)

## Install

1. Complete the initial setup (use a pretty simple password, like 123456, you can change it later!)
2. Update computer's name to "rose"
3. Install nix (via [DeterminateSystems](https://determinate.systems/nix-installer/))
4. [RTFD](https://github.com/nix-darwin/nix-darwin) (nix-darwin)

```shell
$ sudo darwin-rebuild switch --flake .#rose

$ nix run nixpkgs#home-manager -- switch --flake .#luisnquin
```
