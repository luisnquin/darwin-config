{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [./options.nix];

  environment.systemPackages = [
    pkgs.vim
  ];

  nix = {
    enable = false;
    settings.experimental-features = "nix-command flakes";
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  programs.fish.enable = true;
  shared.aliases.enable = true;
  system.primaryUser = "luisnquin";

  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;

    taps = {
      "nikitabobko/aerospace" = inputs.aerospace;
    };
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
    casks = [
      "google-chrome"
      "autodesk-fusion"
      "nikitabobko/tap/aerospace"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };

  local.dock = rec {
    enable = true;
    username = config.system.primaryUser;
    entries = let
      mkHomeAppPath = appName: "/Users/${username}/Applications/Home Manager Apps/${appName}";
    in [
      {path = "/System/Applications/App Store.app";}
      {path = mkHomeAppPath "Zen Browser (Beta).app";}
      {path = "/Applications/Ghostty.app/";}
      {path = mkHomeAppPath "Notion.app";}
      {path = "/Applications/Google Chrome.app/";}
      {path = "/Users/${username}/Applications/Autodesk Fusion.app";}
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
