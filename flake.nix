{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    black-terminal = {
      url = "github:luisnquin/black-terminal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    black-terminal,
    home-manager,
    nix-homebrew,
    zen-browser,
    nix-darwin,
    nixpkgs,
    self,
    ...
  } @ inputs: {
    # $ darwin-rebuild build --flake .#dyx
    darwinConfigurations."dyx" = nix-darwin.lib.darwinSystem {
      modules = [
        black-terminal.darwinModules.default
        nix-homebrew.darwinModules.default
        ./configuration.nix
      ];
      specialArgs = {inherit inputs;};
    };

    homeConfigurations."luisnquin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = {inherit inputs;};
      modules = [
        black-terminal.homeModules.default
        zen-browser.homeModules.default
        ./home.nix
      ];
    };
  };
}
