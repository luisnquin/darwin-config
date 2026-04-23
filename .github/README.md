# MacOS config (nix)

## Setup

1. Complete the initial macOS setup (use a pretty simple password, like 123456, you can change it later)
2. Update computer's name to "rose"
3. Execute `xcode-select --install` (Command Line Tools)
4. Install nix via [DeterminateSystems](https://determinate.systems/nix-installer/) (TODO: try recommended [Lix variant](https://lix.systems/install/#on-any-other-linuxmacos-system))
5. Generate ssh key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
6. Add the generated key to your github account
7. Clone this repo: `nix run nixpkgs#git -- clone git@github.com:luisnquin/darwin-config.git ~/.dotfiles`
8. cd ~/.dotfiles
9. Execute `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#rose`
10. Execute `sudo tailscale up --ssh`
11. Install XCode using the App Store (required for iOS development & proper toolchain).

## Rebuild

```shell
$ sudo darwin-rebuild switch --flake .#rose
```
