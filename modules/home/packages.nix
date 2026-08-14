{
  flake.modules.homeManager.packages = {pkgs, ...}: {
    home.packages = with pkgs; [
      alejandra
      nixgrep
      phone
      senv
    ];
  };
}
