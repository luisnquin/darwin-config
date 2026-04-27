{inputs, ...}: {
  flake.modules.darwin.nix = {pkgs, ...}: {
    nix = {
      enable = true;
      settings.experimental-features = "nix-command flakes";
      package = pkgs.lix;
    };

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      overlays = [
        inputs.nixpkgs-extra.overlays.default
        inputs.senv.overlays.default
        inputs.self.overlays.ollama
      ];
      config.allowUnfree = true;
    };

    system = {
      primaryUser = "luisnquin";
      stateVersion = 6;
    };
  };
}
