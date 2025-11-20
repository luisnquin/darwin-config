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
  };

  outputs = {
    home-manager,
    zen-browser,
    nix-darwin,
    nixpkgs,
    self,
    ...
  } @ inputs: {
    # $ darwin-rebuild build --flake .#dyx
    darwinConfigurations."dyx" = nix-darwin.lib.darwinSystem {
      modules = [
        ./configuration.nix
      ];
      specialArgs = {inherit inputs;};
    };

    homeConfigurations."luisnquin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = {inherit inputs;};
      modules = [
        ./home.nix
        zen-browser.homeModules.default
      ];
    };
  };
}
