{inputs, ...}: {
  # Only `phone` out of the set nixos-config defines, and resolved against this
  # host's nixpkgs instead of the one its subflake pins.
  flake.overlays.phone = final: prev: {
    inherit (inputs.nixos-config-pkgs.overlays.default final prev) phone;
  };
}
