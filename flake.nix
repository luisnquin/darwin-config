{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    black-terminal.url = "github:luisnquin/black-terminal";
    senv = {
      url = "github:luisnquin/senv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-extra = {
      url = "github:0xc000022070/nixpkgs-extra";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        flake-utils.inputs.systems.follows = "systems";
        nix-steipete-tools.inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    black-terminal,
    nixpkgs-extra,
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
        home-manager.darwinModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs;};
            users.luisnquin = {
              imports = [
                black-terminal.homeModules.default
                zen-browser.homeModules.default
                openclaw.homeManagerModules.openclaw
                ./home
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
