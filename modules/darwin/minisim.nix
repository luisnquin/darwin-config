{inputs, ...}: {
  flake.modules.darwin.minisim = {
    config,
    pkgs,
    ...
  }: let
    inherit (inputs.self.lib) ext;
  in {
    environment.systemPackages = [(pkgs.callPackage ../../pkgs/third-party/opendevicehub {})];

    local.signedApps.MiniSim = {
      source = "${pkgs.minisim}/Applications/MiniSim.app";
      agent = "minisim";
    };

    # Xcode boots into OpenDeviceHub's windows instead of opening Device Hub,
    # and quitting Device Hub leaves those simulators running.
    system.defaults.CustomUserPreferences."com.apple.dt.Xcode".DVTiPhoneSimulatorAlwaysLaunchInCoreSimulatorSession = true;
    system.defaults.CustomUserPreferences."com.apple.dt.Devices".shutdownStartedDevicesOnQuit = false;

    system.defaults.CustomUserPreferences."io.github.mastersam07.simviewer" = {
      "opendevicehub.settings.bootMostRecentOnStart" = "false";
      "opendevicehub.settings.shutdownOnWindowClose" = "false";
    };

    system.defaults.CustomUserPreferences."com.oskarkwasniewski.MiniSim" = {
      isOnboardingFinished = true;
      enableiOSSimulators = true;
      enableAndroidEmulators = true;
      androidHome = config.home-manager.users.${config.system.primaryUser}.local.android.sdk;
      preferedTerminal = "com.apple.Terminal";
      # Cmd+Option+E, as carbon key codes. Declared because dropping the cask
      # makes `homebrew.onActivation.cleanup = "zap"` delete this domain's plist,
      # and the zap runs after nix-darwin has written its defaults.
      KeyboardShortcuts_toggleMiniSim = ''{"carbonModifiers":2560,"carbonKeyCode":14}'';
    };

    # MiniSim is LSUIElement, so its menu bar icon exists only while the process
    # runs. Its own "launch at login" toggle goes through SMLoginItemSetEnabled,
    # whose registration lives in the SIP-protected backgrounditems.btm and does
    # not survive the bundle being replaced. Owning the launch here keeps it
    # declarative. `open` is used over the executable so LaunchServices attributes
    # the accessibility and Apple Events prompts to MiniSim rather than to launchd.
    #
    # The emulator list comes from ANDROID_AVD_HOME, which the app reads from
    # the session it is opened into, so the variables have to be in place
    # before then rather than whenever the agent that owns them happens to run.
    launchd.user.agents.minisim.serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "exec ${pkgs.writeShellScript "minisim-open" ''
          while ! /sbin/mount | /usr/bin/grep -Fq " on ${ext.path} ("; do
            /bin/sleep 1
          done

          ${config.local.ext.guiEnvScript}
          /usr/bin/pkill -x MiniSim
          while /usr/bin/pgrep -qx MiniSim; do /bin/sleep 0.2; done
          for _ in 1 2 3 4 5; do
            /usr/bin/open -n -a /Applications/MiniSim.app && exit 0
            /bin/sleep 2
          done
          exit 1
        ''}"
      ];
      RunAtLoad = true;
    };
  };
}
