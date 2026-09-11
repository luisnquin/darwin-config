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
        CARGO_HOME = "${cache}/cargo";
        CP_HOME_DIR = "${cache}/cocoapods";
        GRADLE_USER_HOME = "${cache}/gradle";
        npm_config_cache = "${cache}/npm";
      };

      file = {
        # Working trees, including the ones no remote has a copy of.
        "Projects".source = outOfStore "${path}/projects";

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
          ]
        }
      '';
    };

    # Xcode.app inherits launchd's environment, never home.sessionVariables.
    targets.darwin.defaults."com.apple.dt.Xcode".IDECustomDerivedDataLocation = "${cache}/xcode/derived-data";
  };
}
