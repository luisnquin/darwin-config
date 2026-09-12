{inputs, ...}: {
  flake.modules.darwin.nix = {pkgs, ...}: {
    nix = {
      enable = true;
      settings.experimental-features = "nix-command flakes";
      package = pkgs.lix;
      optimise.automatic = true;
      channel.enable = false;
    };

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      overlays = [
        inputs.nixpkgs-extra.overlays.default
        inputs.nixos-config-overlays.overlays.default
        inputs.self.overlays.minisim
        inputs.self.overlays.pymobiledevice3
        inputs.self.overlays.roomy
      ];
      config.allowUnfree = true;
    };

    system = {
      primaryUser = "luisnquin";
      stateVersion = 7;
    };
  };
}
