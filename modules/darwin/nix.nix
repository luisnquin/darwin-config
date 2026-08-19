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
        inputs.self.overlays.a2a-sdk
        inputs.self.overlays.lix
        inputs.self.overlays.minisim
        inputs.self.overlays.phone
        inputs.self.overlays.pymobiledevice3
        inputs.self.overlays.sickdeck
      ];
      config.allowUnfree = true;
    };

    system = {
      primaryUser = "luisnquin";
      stateVersion = 6;
    };
  };
}
