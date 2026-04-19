{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
  };

  outputs = {
    black-terminal,
    flake-parts,
    home-manager,
    nix-homebrew,
    zen-browser,
    nix-darwin,
    nixpkgs,
    self,
    systems,
    ...
  } @ inputs: let
    collectTopLevelModules = dir: let
      entries = builtins.readDir dir;
    in
      nixpkgs.lib.concatLists (nixpkgs.lib.mapAttrsToList (
          name: type: let
            path = dir + "/${name}";
          in
            if type == "directory"
            then collectTopLevelModules path
            else if type == "regular" && nixpkgs.lib.hasSuffix ".nix" name && name != "flake.nix" && name != "default.nix"
            then [path]
            else []
        )
        entries);
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [flake-parts.flakeModules.modules] ++ collectTopLevelModules ./modules;

      config = {
        systems = import systems;

        flake = {
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
                      self.modules.homeManager.luisnquin
                    ];
                  };
                };
              }
              self.modules.darwin.dyx
            ];
            specialArgs = {inherit inputs;};
          };
        };
      };
    };
}
