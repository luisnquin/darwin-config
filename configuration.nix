{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.vim
    pkgs.vscode
    # Què? Safari es una basura?
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".beta
  ];

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

 nix.enable = false;

  # Enable alternative shell support in nix-darwin.
  programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
