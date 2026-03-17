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
    black-terminal.url = "github:luisnquin/black-terminal";
    openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = {
    black-terminal,
    home-manager,
    nix-homebrew,
    zen-browser,
    nix-darwin,
    openclaw,
    nixpkgs,
    self,
    ...
  } @ inputs: {
    # $ darwin-rebuild build --flake .#dyx
    darwinConfigurations."dyx" = nix-darwin.lib.darwinSystem {
      modules = [
        black-terminal.darwinModules.default
        nix-homebrew.darwinModules.default
        home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs;};
            users.luisnquin = {
              imports = [
                black-terminal.homeModules.default
                zen-browser.homeModules.default
                openclaw.homeModules.default
                ./home.nix
              ];
            };
          };
        }
        ./configuration.nix
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
