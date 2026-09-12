{inputs, ...}: {
  flake.modules.homeManager.packages = {pkgs, ...}: let
    phone = inputs.nixos-config-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.phone;
  in {
    home.packages = with pkgs; [
      alejandra
      nixgrep
      # the accessibility bridge the phone CLI on another machine drives over ssh
      phone.receiver
      senv
    ];
  };
}
