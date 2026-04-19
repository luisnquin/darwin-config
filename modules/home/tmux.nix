{
  flake.modules.homeManager.tmux = {pkgs, ...}: {
    shared.tmux = {
      enable = true;
      theme = {
        plugin = pkgs.tmuxPlugins.rose-pine;
        extraConfig = "";
      };
    };
  };
}
