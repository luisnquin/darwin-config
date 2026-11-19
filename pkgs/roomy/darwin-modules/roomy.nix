{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
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

  lowOn = volumes: ''
    low=
    for v in ${lib.escapeShellArgs volumes}; do
      [ -d "$v" ] || continue
      free=$(/bin/df -g "$v" | /usr/bin/awk 'NR == 2 { print $4 }')
      [ "$free" -lt ${toString cfg.minFreeGB} ] && low=1
    done
    [ -n "$low" ] || exit 0
    date
  '';

  # Everything here is safe for live emulator work: AVDs are never touched,
  # `simctl delete unavailable` only removes devices whose runtime is already
  # gone, and the dyld cache wipe is skipped while any simulator is booted.
  cleanupScript = pkgs.writeShellScript "roomy-cleanup" ''
    ${lowOn (["/System/Volumes/Data"] ++ cfg.extraVolumes)}
    set -x

    /usr/bin/xcrun simctl delete unavailable || true

    for root in ${lib.escapeShellArgs cfg.scratchDirs}; do
      [ -d "$root" ] || continue
      /usr/bin/find "$root/" -type d \
        \( -name node_modules -o -name target -o -name Pods -o -name .build -o -name .gradle \) \
        -mtime +3 -prune -exec rm -rf {} + 2>/dev/null || true
    done

    # Asking Xcode where it puts DerivedData keeps this correct when the
    # location is relocated, which IDECustomDerivedDataLocation exists to do.
    derivedData=$(/usr/bin/defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation 2>/dev/null) \
      || derivedData="$HOME/Library/Developer/Xcode/DerivedData"

    /usr/bin/find "$derivedData" \
      -mindepth 1 -maxdepth 1 -mtime +7 -exec rm -rf {} + 2>/dev/null || true

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

    sessionEnvironment = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = lib.literalExpression "config.local.ext.guiEnvScript";
      description = ''
        Script run before Roomy is opened. Roomy takes the location of the
        Gradle, Cargo, npm, CocoaPods and AVD caches from the variables that
        name them, which is the only way it can tell which drive they are on
        once they are relocated. Whatever agent owns those variables starts in
        no particular order relative to this one, so they are put in place here
        rather than assumed to be there already.
      '';
    };

    app = mkOption {
      type = types.str;
      default = "${cfg.package}/Applications/Roomy.app";
      defaultText = lib.literalExpression ''"''${cfg.package}/Applications/Roomy.app"'';
      description = ''
        Bundle the agent opens. Set it to a copy signed with a stable identity
        to keep permission grants across rebuilds; the package is then left
        out of the system profile so the app is not listed twice.
      '';
    };

    minFreeGB = mkOption {
      type = types.ints.positive;
      default = 40;
      description = "Free space, in GiB, below which the cleanup jobs act.";
    };

    extraVolumes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Mount points watched next to the boot volume.";
    };

    scratchDirs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Directories whose stale build output may be deleted.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [roomyGc] ++ lib.optional (lib.hasPrefix "${cfg.package}" cfg.app) cfg.package;

    # Roomy is LSUIElement, so its menu bar icon exists only while the process
    # runs. `open` is used over the executable so LaunchServices attributes any
    # permission prompts to Roomy rather than to launchd.
    launchd.user.agents.roomy.serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "exec ${pkgs.writeShellScript "roomy-open" ''
          ${lib.optionalString (cfg.sessionEnvironment != null) "${cfg.sessionEnvironment}"}
          /usr/bin/pkill -x Roomy
          while /usr/bin/pgrep -qx Roomy; do /bin/sleep 0.2; done
          for _ in 1 2 3 4 5; do
            /usr/bin/open -n -a ${cfg.app} && exit 0
            /bin/sleep 2
          done
          exit 1
        ''}"
      ];
      RunAtLoad = true;
    };

    # Replaces nix.gc.automatic, whose plain nix-collect-garbage would hit the
    # chmod wall described above.
    # /bin/sh, not a store path: this can start before /nix mounts.
    launchd.daemons.roomy-gc.serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path ${roomyGc} && exec ${pkgs.writeShellScript "roomy-gc-when-low" ''
          ${lowOn ["/System/Volumes/Data"]}
          exec ${roomyGc}/bin/roomy-gc
        ''}"
      ];
      StartInterval = 600;
      StandardOutPath = "/var/log/roomy-gc.log";
      StandardErrorPath = "/var/log/roomy-gc.log";
    };

    launchd.user.agents.roomy-cleanup.serviceConfig = {
      ProgramArguments = ["/bin/sh" "-c" "exec ${cleanupScript}"];
      StartInterval = 600;
      StandardOutPath = "/Users/${config.system.primaryUser}/Library/Logs/roomy-cleanup.log";
      StandardErrorPath = "/Users/${config.system.primaryUser}/Library/Logs/roomy-cleanup.log";
    };
  };
}
