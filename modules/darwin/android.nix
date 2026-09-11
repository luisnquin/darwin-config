{
  flake.modules.darwin.android = {config, ...}: let
    sdk = config.home-manager.users.${config.system.primaryUser}.local.android.sdk;
  in {
    # Apps launched from the Dock inherit launchd's environment, never
    # home.sessionVariables, so Android Studio would offer to provision a
    # second sdk under ~/Library instead of adopting the one on the volume.
    launchd.envVariables = {
      ANDROID_HOME = sdk;
      ANDROID_SDK_ROOT = sdk;
    };
  };
}
