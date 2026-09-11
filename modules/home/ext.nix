{
  flake.modules.homeManager.ext = {
    config,
    lib,
    ...
  }: let
    ext = config.local.ext.path;

    outOfStore = config.lib.file.mkOutOfStoreSymlink;
  in {
    home = {
      sessionVariables = {
        ANDROID_AVD_HOME = "${ext}/android/avd";
        CARGO_HOME = "${ext}/cargo";
        CP_HOME_DIR = "${ext}/cocoapods";
        GRADLE_USER_HOME = "${ext}/gradle";
        npm_config_cache = "${ext}/npm";
      };

      # CoreSimulatorService is started by launchd and Xcode exposes no
      # device-set preference, so these two have no knob but the filesystem.
      file = {
        "Library/Developer/CoreSimulator/Devices".source = outOfStore "${ext}/xcode/simulator-devices";
        "Library/Developer/Xcode/iOS DeviceSupport".source = outOfStore "${ext}/xcode/ios-device-support";
      };

      # Only the paths no tool creates for itself.
      activation.extDirs = lib.hm.dag.entryBetween ["checkLinkTargets"] ["extMount"] ''
        $DRY_RUN_CMD /bin/mkdir -p ${
          lib.escapeShellArgs (map (dir: "${ext}/${dir}") [
            "android/avd"
            "xcode/ios-device-support"
            "xcode/simulator-devices"
          ])
        }
      '';
    };

    # Xcode.app inherits launchd's environment, never home.sessionVariables.
    targets.darwin.defaults."com.apple.dt.Xcode".IDECustomDerivedDataLocation = "${ext}/xcode/derived-data";
  };
}
