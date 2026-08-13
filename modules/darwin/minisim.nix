{
  flake.modules.darwin.minisim = {config, ...}: let
    home = "/Users/${config.system.primaryUser}";
  in {
    system.defaults.CustomUserPreferences."com.oskarkwasniewski.MiniSim" = {
      isOnboardingFinished = true;
      enableiOSSimulators = true;
      enableAndroidEmulators = true;
      androidHome = "${home}/Library/Android/sdk";
      preferedTerminal = "com.apple.Terminal";
    };
  };
}
