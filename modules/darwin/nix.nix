{inputs, ...}: {
  flake.modules.darwin.nix = {pkgs, ...}: {
    nix = {
      enable = true;
      settings.experimental-features = "nix-command flakes";
      package = pkgs.lix;
      optimise.automatic = true;
      channel.enable = false;
      linux-builder.enable = true;
    };

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      overlays = [
        inputs.nixpkgs-extra.overlays.default
        inputs.nixos-config-overlays.overlays.default
        inputs.self.overlays.minisim
        inputs.self.overlays.pymobiledevice3
        inputs.self.overlays.roomy
        inputs.self.overlays.sponsorbar-hover
      ];
      config.allowUnfree = true;
    };

    system = {
      primaryUser = "luisnquin";
      stateVersion = 7;
    };
  };
}
