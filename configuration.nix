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
    entries = [
      {path = "/Users/luisnquin/Applications/Home\ Manager\ Apps/Visual\ Studio\ Code.app";}
      {path = "/Users/luisnquin/Applications/Home\ Manager\ Apps/Zen\ Browser\ \(Beta\).app";}
      {path = "/Applications/Ghostty.app/";}
    ];
  };

  environment.shellAliases = {
    "dot" = "cd ~/.dotfiles";
  };

  # Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
