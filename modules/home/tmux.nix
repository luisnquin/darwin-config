{
  flake.modules.homeManager.tmux = {pkgs, ...}: {
    shared.tmux = {
      enable = true;
      autoStart = true;
      theme = {
        plugin = pkgs.tmuxPlugins.rose-pine;
        extraConfig = "";
      };

      status = {
        ssh.enable= false;
        gpg.enable = false;
        lsyncd.enable = false;
        gitmux.enable = true;
      };
    };
  };
}
