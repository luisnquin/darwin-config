# MacOS config (nix)

## Setup

1. Complete the initial macOS setup (use a pretty simple password, like 123456, you can change it later)
2. Update computer's name to "rose"
3. Execute `xcode-select --install` (Command Line Tools)
4. Install nix via [Lix variant](https://lix.systems/install/#on-any-other-linuxmacos-system)
5. Generate ssh key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
6. Add the generated key to your github account
7. Attach the external SSD. macOS mounts it at `/Volumes/ext`; the first switch moves it to `/ext`.
8. Unless the volume already carries it, clone this repo onto it: `nix run nixpkgs#git -- clone git@github.com:luisnquin/darwin-config.git /Volumes/ext/projects/github.com/luisnquin/darwin-config`
9. cd into the clone
10. Execute `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#rose`
11. cd `/ext/projects/github.com/luisnquin/darwin-config`, the volume moved during the switch
12. Execute `sudo tailscale up --ssh`
13. Install XCode using the App Store (required for iOS development & proper toolchain).
14. Sharing > Enable Screen Sharing & Remote Login

## Rebuild

```shell
$ sudo darwin-rebuild switch --flake .#rose
```
