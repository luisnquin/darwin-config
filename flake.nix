{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
    nix-darwin,
    self,
    ...
  } @ inputs: {
    # $ darwin-rebuild build --flake .#dyx
    darwinConfigurations."dyx" = nix-darwin.lib.darwinSystem {
      modules = [./configuration.nix];
      specialArgs = {inherit inputs;};
    };
  };
}
