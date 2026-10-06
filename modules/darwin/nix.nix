{inputs, ...}: {
  flake.modules.darwin.nix = {
    lib,
    pkgs,
    ...
  }: let
    storeUUID = inputs.self.lib.ext.nixStoreUUID;
  in {
    # This runs before /nix exists, so every executable must come from macOS.
    launchd.daemons = lib.mkIf inputs.self.lib.ext.nixStoreExternal {
      darwin-store.serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            set -eu
            uuid=${storeUUID}
            mountedUUID=$(/usr/sbin/diskutil info -plist /nix | /usr/bin/plutil -extract VolumeUUID raw -o - - 2>/dev/null) || mountedUUID=
            if [ "$mountedUUID" = "$uuid" ]; then
              exit 0
            fi
            if /sbin/mount | /usr/bin/grep -q ' on /nix ('; then
              echo 'Another volume is mounted at /nix' >&2
              exit 1
            fi
            locked=$(/usr/sbin/diskutil info -plist "$uuid" | /usr/bin/plutil -extract Locked raw -o - -)
            if [ "$locked" = true ]; then
              /usr/bin/security find-generic-password -a 'Nix Store' -s 'Nix Store' -w /Library/Keychains/System.keychain |
                /usr/sbin/diskutil apfs unlockVolume "$uuid" -nomount -stdinpassphrase
            fi
            volumeMount=$(/usr/sbin/diskutil info -plist "$uuid" | /usr/bin/plutil -extract MountPoint raw -o - - 2>/dev/null) || volumeMount=
            if [ -n "$volumeMount" ]; then
              /usr/sbin/diskutil unmount "$uuid"
            fi
            /usr/sbin/diskutil mount -mountPoint /nix "$uuid"
          ''
        ];
        RunAtLoad = true;
        StartOnMount = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
      };
    };

    nix = {
      enable = true;
      settings.experimental-features = "nix-command flakes";
      package = pkgs.lix;
      optimise.automatic = true;
      channel.enable = false;
    };

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      overlays = [
        inputs.nixpkgs-extra.overlays.default
        inputs.nixos-config-overlays.overlays.default
        inputs.self.overlays.minisim
        inputs.self.overlays.pymobiledevice3
        inputs.self.overlays.roomy
        inputs.self.overlays.sponsorbar-hover
      ];
      config.allowUnfree = true;
    };

    system = {
      primaryUser = "luisnquin";
      stateVersion = 7;
    };
  };
}
