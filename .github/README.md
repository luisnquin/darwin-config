# MacOS config (nix)

## Setup

1. Complete the initial macOS setup (use a pretty simple password, like 123456, you can change it later)
2. Update computer's name to "rose"
3. Execute `xcode-select --install` (Command Line Tools)
4. Install Xcode from the App Store and launch it once, to let it finish its
   components and to accept the license. MiniSim is built from source against
   `/Applications/Xcode.app` and step 11 fails without it. Start the download
   now; the steps below run alongside it
5. Install nix via [Lix variant](https://lix.systems/install/#on-any-other-linuxmacos-system)
6. Generate ssh key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
7. Add the generated key to your github account
8. Clone this repo: `nix run nixpkgs#git -- clone git@github.com:luisnquin/darwin-config.git ~/.dotfiles`
9. cd ~/.dotfiles
10. Attach the external SSD; the switch mounts it at `/ext` and fails without it
11. Execute `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#rose`
12. Execute `sudo tailscale up --ssh`
13. Sharing > Enable Screen Sharing; the switch turns Remote Login on by itself
14. Privacy & Security > Full Disk Access > add the terminal, otherwise TCC denies
    it `/ext` over ssh with `Operation not permitted`, and sshd cannot raise the
    consent prompt itself
15. Run `android-sdk-provision` unless `/ext/cache/android/sdk` is already
    populated; it downloads ~11G. MiniSim shells out to the emulator in there
    and reports status code 127 until it exists

## Rebuild

```shell
$ sudo darwin-rebuild switch --flake .#rose
```
