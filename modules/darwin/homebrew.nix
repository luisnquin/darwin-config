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
    };
  };
}
