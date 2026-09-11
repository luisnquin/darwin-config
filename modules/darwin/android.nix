{
  flake.modules.darwin.android = {
    config,
    lib,
    ...
  }: let
    hm = config.home-manager.users.${config.system.primaryUser};

    sdk = hm.local.android.sdk;

    variables = {
      ANDROID_HOME = sdk;
      ANDROID_SDK_ROOT = sdk;
      inherit (hm.home.sessionVariables) ANDROID_AVD_HOME;
    };
  in {
    # Apps launched from the Dock inherit launchd's environment, never
    # home.sessionVariables, so Android Studio would offer to provision a
    # second sdk under ~/Library instead of adopting the one on the volume,
    # and MiniSim would list no emulator at all, the avds not being under
    # ~/.android either.
    #
    # launchd.user.envVariables would be the declarative way in, but it writes
    # them with sudo --user, which lands them in whichever bootstrap namespace
    # the switch was started from: the Aqua session when it runs in a terminal
    # window, the background one over ssh, and only Aqua is read by GUI apps.
    # asuser names that session outright. It has nowhere to write when nobody
    # is logged in, and a switch is not worth failing over that.
    system.activationScripts.postActivation.text = ''
      uid=$(/usr/bin/id -u ${config.system.primaryUser})

      ${lib.concatLines (lib.mapAttrsToList (name: value: ''
          /bin/launchctl asuser "$uid" /bin/launchctl setenv ${name} ${lib.escapeShellArg value} || true'')
        variables)}
    '';
  };
}
