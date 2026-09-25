{
  flake.modules.darwin.homebrew = {
    config,
    pkgs,
    ...
  }: let
    sponsorbarTap = pkgs.runCommand "homebrew-sponsorbar-tap" {} ''
      cp -R ${./homebrew} "$out"
    '';
  in {
    nix-homebrew = {
      enable = true;
      user = config.system.primaryUser;
      taps."luisnquin/homebrew-sponsorbar" = sponsorbarTap;
      trust.taps = ["luisnquin/sponsorbar"];
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;

        extraEnv = {
          HOMEBREW_NO_ENV_HINTS = "1";
          HOMEBREW_NO_ANALYTICS = "1";
        };
      };

      taps = [
        "nikitabobko/tap"
        "luisnquin/sponsorbar"
      ];

      # CocoaPods must come from Homebrew: the nixpkgs build is not on PATH for
      # Xcode, so iOS pod installs resolve this one. Undeclared it counted as
      # drift, and `brew bundle --cleanup` exits non-zero on drift, which aborts
      # the whole activation script before home-manager ever runs.
      brews = [
        "cocoapods"
      ];

      casks = [
        "android-commandlinetools"
        "android-studio"
        "ghostty"
        "luisnquin/sponsorbar/sponsorbar"
      ];
    };
  };
}
