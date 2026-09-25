{
  flake.modules.homeManager.ext = {
    config,
    lib,
    ...
  }: let
    inherit (config.local.ext) cache path;

    outOfStore = config.lib.file.mkOutOfStoreSymlink;
  in {
    home = {
      sessionVariables = {
        ANDROID_AVD_HOME = "${cache}/android/avd";
        BUN_INSTALL_CACHE_DIR = "${cache}/bun";
        CARGO_HOME = "${cache}/cargo";
        CP_HOME_DIR = "${cache}/cocoapods";
        CP_CACHE_DIR = "${cache}/cocoapods-downloads";
        DOTSLASH_CACHE = "${cache}/dotslash";
        GRADLE_USER_HOME = "${cache}/gradle";
        HOMEBREW_CACHE = "${cache}/homebrew";
        JAVA_TOOL_OPTIONS = "-Djava.io.tmpdir=${cache}/tmp";
        PIP_CACHE_DIR = "${cache}/pip";
        UV_CACHE_DIR = "${cache}/uv";
        XDG_CACHE_HOME = "${cache}/xdg";
        TMPDIR = "${cache}/tmp/";
        npm_config_cache = "${cache}/npm";
      };

      file = {
        # Working trees, including the ones no remote has a copy of.
        "Projects".source = outOfStore "${path}/projects";
        ".bun/install/cache".source = outOfStore "${cache}/bun";
        ".cache".source = outOfStore "${cache}/xdg";
        "${config.home.homeDirectory}/.cache/.keep".enable = false;
        "Library/Caches/Homebrew".source = outOfStore "${cache}/homebrew";
        "Library/Caches/CocoaPods".source = outOfStore "${cache}/cocoapods-downloads";
        "Library/Caches/org.swift.swiftpm".source = outOfStore "${cache}/swiftpm";
        "Library/Caches/Google".source = outOfStore "${cache}/google";
        "Library/Developer/Xcode/Archives".source = outOfStore "${path}/xcode/archives";

        # Xcode has no preference for this one, so a symlink is the only knob.
        # CoreSimulator/Devices cannot follow: TCC denies CoreSimulatorService
        # every read and write on an external volume, whatever the mount point,
        # and a daemon cannot raise the consent prompt that would lift it.
        "Library/Developer/Xcode/iOS DeviceSupport".source = outOfStore "${cache}/xcode/ios-device-support";
      };

      # Only the paths no tool creates for itself.
      activation.extDirs = lib.hm.dag.entryBetween ["checkLinkTargets"] ["extMount"] ''
        $DRY_RUN_CMD /bin/mkdir -p ${
          lib.escapeShellArgs [
            "${path}/projects"
            "${cache}/android/avd"
            "${cache}/xcode/ios-device-support"
            "${cache}/bun"
            "${cache}/xdg"
            "${cache}/homebrew"
            "${cache}/cocoapods-downloads"
            "${cache}/swiftpm"
            "${cache}/dotslash"
            "${cache}/google"
            "${cache}/pip"
            "${cache}/uv"
            "${cache}/tmp"
            "${path}/xcode/archives"
          ]
        }
        $DRY_RUN_CMD /bin/chmod 0700 ${lib.escapeShellArg "${cache}/tmp"}
      '';
    };

    # Xcode.app inherits launchd's environment, never home.sessionVariables.
    targets.darwin.defaults."com.apple.dt.Xcode".IDECustomDerivedDataLocation = "${cache}/xcode/derived-data";
  };
}
