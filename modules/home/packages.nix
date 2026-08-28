{
  flake.modules.homeManager.packages = {pkgs, ...}: {
    home.packages = with pkgs; [
      alejandra
      nixgrep
      # both halves: the CLI, which now runs whole project commands here rather
      # than being driven over ssh, and the accessibility bridge it calls
      phone
      phone.receiver
      senv
    ];
  };
}
