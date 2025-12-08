{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [./options.nix];

  environment.systemPackages = [
    pkgs.vim
    pkgs.nano # replace default editor
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
    ];
    masApps = {
      Xcode = 497799835;
    };
  };

  services.aerospace = {
    enable = true;

    settings = {
      start-at-login = false; # managed by hm

      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.bottom = 5;
        outer.top = [{monitor.main = 10;} 10];
        outer.right = 5;
        outer.left = 5;
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";
        alt-f = "fullscreen";
      };
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
