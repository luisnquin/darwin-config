{inputs, ...}: {
  flake.modules.darwin.minisim = {
    config,
    pkgs,
    ...
  }: let
    inherit (inputs.self.lib) ext;
  in {
    environment.systemPackages = [pkgs.minisim];

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
        "${pkgs.writeShellScript "minisim-open" ''
          while ! /sbin/mount | /usr/bin/grep -Fq " on ${ext.path} ("; do
            /bin/sleep 1
          done

          ${config.local.ext.guiEnvScript}
          exec /usr/bin/open -a ${pkgs.minisim}/Applications/MiniSim.app
        ''}"
      ];
      RunAtLoad = true;
    };
  };
}
