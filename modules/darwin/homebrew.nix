{
  flake.modules.darwin.homebrew = {config, ...}: {
    nix-homebrew = {
      enable = true;
      user = config.system.primaryUser;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };

      taps = [
        "nikitabobko/tap"
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
        "minisim"
      ];
    };
  };
}
