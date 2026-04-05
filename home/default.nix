{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../options/hm
    ./modules
  ];

  programs.zen-browser.enable = true;

  home = {
    stateVersion = "25.05";
    username = "luisnquin";
    homeDirectory = pkgs.lib.mkForce "/Users/luisnquin";
  };

  shared = {
    bat.enable = true;
    btop.enable = true;
    direnv.enable = true;
    eza.enable = true;
    fzf.enable = true;
    macchina.enable = true;
    ghostty.enable = true;
    git = {
      enable = true;
      user = {
        name = "Luis Quiñones Requelme";
        email = "luis@quinones.pro";
      };
    };
    lazygit.enable = true;
    less.enable = true;
    magic-wormhole.enable = true;
    starship.enable = true;
    tmux = {
      enable = true;
      theme = {
        plugin = pkgs.tmuxPlugins.rose-pine;
        extraConfig = "";
      };
    };
    zoxide.enable = true;
    zsh.enable = true;
  };

  home = {
    packages = with pkgs; [
      alejandra
      nixgrep
      senv
    ];

    shellAliases = {
      "pr" = "cd ~/Projects";
    };
  };

  programs = {
    bun.enable = true;
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # disable greeting
      '';
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "fzf"; # Ctrl + R
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "done";
          src = pkgs.fishPlugins.done.src;
        }
      ];
    };

    npm = {
      enable = true;
      package = pkgs.hiPrio pkgs.nodejs_25;
    };

    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      };
    };
  };
}
