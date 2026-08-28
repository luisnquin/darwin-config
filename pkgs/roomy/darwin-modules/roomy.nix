{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkPackageOption;
  cfg = config.programs.roomy;

  # nix GC chmods store paths before unlinking them, and TCC's App Management
  # protection denies chmod inside a LaunchServices-registered .app bundle
  # even for root — so one dead Roomy/MiniSim build aborts the whole GC with
  # "Operation not permitted". Plain rm needs no chmod (root may unlink from
  # read-only directories), so dead app bundles are swept first. Roomy's
  # "Trim old generations" tip copies `sudo roomy-gc`, which is why the script
  # ships with the app's module.
  roomyGc = pkgs.writeShellScriptBin "roomy-gc" ''
    ${config.nix.package}/bin/nix-store --gc --print-dead 2>/dev/null \
      | while read -r path; do
        if [ -d "$path/Applications" ]; then
          echo "purging app bundle $path"
          rm -rf "$path"
        fi
      done
    exec ${config.nix.package}/bin/nix-collect-garbage --delete-older-than 14d
  '';

  # Everything here is safe for live emulator work: AVDs in ~/.android/avd
  # are never touched, `simctl delete unavailable` only removes devices whose
  # runtime is already gone, and the dyld cache wipe is skipped while any
  # simulator is booted.
  cleanupScript = pkgs.writeShellScript "roomy-cleanup" ''
    set -x

    /usr/bin/xcrun simctl delete unavailable || true

    /usr/bin/find "$HOME/Library/Developer/Xcode/DerivedData" \
      -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null || true

    if ! /usr/bin/xcrun simctl list devices booted | grep -q Booted; then
      rm -rf "$HOME/Library/Developer/CoreSimulator/Caches/dyld" || true
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
      /opt/homebrew/bin/brew cleanup --prune=all || true
    fi
  '';
in {
  options.programs.roomy = {
    enable = mkEnableOption "Roomy, a menu bar free-disk-space indicator";

    package = mkPackageOption pkgs "roomy" {};
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package roomyGc];

    # Roomy is LSUIElement, so its menu bar icon exists only while the process
    # runs. `open` is used over the executable so LaunchServices attributes any
    # permission prompts to Roomy rather than to launchd.
    launchd.user.agents.roomy.serviceConfig = {
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "${cfg.package}/Applications/Roomy.app"
      ];
      RunAtLoad = true;
    };

    # Replaces nix.gc.automatic, whose plain nix-collect-garbage would hit the
    # chmod wall described above.
    launchd.daemons.roomy-gc.serviceConfig = {
      ProgramArguments = ["${roomyGc}/bin/roomy-gc"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 12;
          Minute = 0;
        }
      ];
      StandardOutPath = "/tmp/roomy-gc.log";
      StandardErrorPath = "/tmp/roomy-gc.log";
    };

    launchd.user.agents.roomy-cleanup.serviceConfig = {
      ProgramArguments = ["${cleanupScript}"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 12;
          Minute = 30;
        }
      ];
      StandardOutPath = "/tmp/roomy-cleanup.log";
      StandardErrorPath = "/tmp/roomy-cleanup.log";
    };
  };
}
