{
  flake.modules.homeManager.cli = {
    shared = {
      bat.enable = true;
      btop.enable = true;
      direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      macchina.enable = true;
      ghostty.enable = true;
      lazygit.enable = true;
      less.enable = true;
      magic-wormhole.enable = true;
      starship.enable = true;
      zoxide.enable = true;
      zsh.enable = true;
    };

    home.shellAliases = {
      "pr" = "cd ~/Projects";
    };
  };
}
