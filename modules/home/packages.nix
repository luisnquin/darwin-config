{
  flake.modules.homeManager.packages = {pkgs, ...}: {
    home.packages = with pkgs; [
      alejandra
      nixgrep
      # the accessibility bridge the phone CLI on another machine drives over ssh
      phone.receiver
      senv
    ];
  };
}
