{
  flake.modules.darwin.minisim = {
    config,
    pkgs,
    ...
  }: let
    home = "/Users/${config.system.primaryUser}";
  in {
    environment.systemPackages = [pkgs.minisim];

    system.defaults.CustomUserPreferences."com.oskarkwasniewski.MiniSim" = {
      isOnboardingFinished = true;
      enableiOSSimulators = true;
      enableAndroidEmulators = true;
      androidHome = "${home}/Library/Android/sdk";
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
    launchd.user.agents.minisim.serviceConfig = {
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "${pkgs.minisim}/Applications/MiniSim.app"
      ];
      RunAtLoad = true;
    };
  };
}
