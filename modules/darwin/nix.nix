{inputs, ...}: {
  flake.modules.darwin.nix = {
    nix = {
      enable = false;
      settings.experimental-features = "nix-command flakes";
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
