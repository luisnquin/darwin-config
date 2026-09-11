{
  flake.modules.darwin.android = {config, ...}: let
    hm = config.home-manager.users.${config.system.primaryUser};

    sdk = hm.local.android.sdk;
  in {
    # Apps launched from the Dock inherit launchd's environment, never
    # home.sessionVariables, so Android Studio would offer to provision a
    # second sdk under ~/Library instead of adopting the one on the volume,
    # and MiniSim would list no emulator at all, the avds not being under
    # ~/.android either. The user domain is where they go because SIP rejects
    # a setenv made as root, and it is the only domain the Aqua session reads.
    launchd.user.envVariables = {
      ANDROID_HOME = sdk;
      ANDROID_SDK_ROOT = sdk;
      inherit (hm.home.sessionVariables) ANDROID_AVD_HOME;
    };
  };
}
