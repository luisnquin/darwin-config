{
  inputs,
  pkgs,
  ...
}: {
  imports = [./options.nix];

  environment.systemPackages = [
    pkgs.vim
  ];

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.enable = false;

  # Enable alternative shell support in nix-darwin.
  programs.fish.enable = true;

  local.dock = {
    enable = true;
    username = "luisnquin";
    entries = let
      mkHomeAppPath = appName: "/Users/luisnquin/Applications/Home Manager Apps/${appName}";
    in [
      {path = "/System/Applications/App Store.app";}
      {path = mkHomeAppPath "Zen Browser (Beta).app";}
      {path = "/Applications/Ghostty.app/";}
      {path = mkHomeAppPath "Notion.app";}
      {path = "/Applications/Google Chrome.app/";}
      {path = mkHomeAppPath "Autodesk Fusion.app";}
    ];
  };

  environment.shellAliases = {
    "dot" = "cd ~/.dotfiles";
  };

  system.primaryUser = "luisnquin";

  nix-homebrew = {
    enable = true;
    user = "luisnquin";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    casks = [
      "google-chrome"
      "autodesk-fusion"
    ];
    masApps = {
      Xcode = 497799835;
    };
  };

  # Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
