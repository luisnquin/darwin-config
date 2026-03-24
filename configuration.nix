{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [./options/darwin/dock.nix];

  networking.hostName = "dyx";

  environment = {
    systemPackages = with pkgs; [
      vim
      nano # replace default editor
      rsync # v3
    ];

    variables = {
      LANG = "en_US.UTF-8";
    };
  };

  nix = {
    enable = false;
    settings.experimental-features = "nix-command flakes";
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    overlays = [
      inputs.openclaw.overlays.default
      inputs.nixpkgs-extra.overlays.default
      inputs.senv.overlays.default
    ];
    config.allowUnfree = true;
  };

  users.users.luisnquin = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXW6vsDRgI/AiOdGnQOTyiz1uLFL0o66u0Ahcw9VWyd luis@quinones.pro"
    ];
  };

  services.openssh.enable = true;

  programs.fish.enable = true;

  shared = {
    aliases.enable = true;
    zsh.enable = true;
  };

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
      "notion"
    ];
    # masApps = {
    #   Xcode = 497799835;
    # };
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
      {path = "/Applications/Notion.app";}
      {path = "/Applications/Google Chrome.app/";}
      {path = "/Users/${username}/Applications/Autodesk Fusion.app";}
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
