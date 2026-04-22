# MacOS config (nix)

## Install

1. Complete the initial setup
2. Update computer's name to "dyx"
3. [RTFD](https://github.com/nix-darwin/nix-darwin) (nix-darwin)

```shell
$ sudo darwin-rebuild switch --flake .#dyx

$ nix run nixpkgs#home-manager -- switch --flake .#luisnquin
```
