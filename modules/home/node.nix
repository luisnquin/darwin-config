{
  flake.modules.homeManager.node = {pkgs, ...}: {
    programs = {
      bun.enable = true;

      npm = {
        enable = true;
        package = pkgs.lib.hiPrio pkgs.nodejs_25;
      };
    };
  };
}
