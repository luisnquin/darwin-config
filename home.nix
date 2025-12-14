{
  config,
  pkgs,
  ...
}: {
  programs.zen-browser.enable = true;

  home = {
    stateVersion = "25.05";
    username = "luisnquin";
    homeDirectory = "/Users/luisnquin";
  };

  nixpkgs.config.allowUnfree = true;

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };

  home = {
    packages = with pkgs; [
      alejandra
      nodejs
      bun
    ];

    shellAliases = {
      "pr" = "cd ~/Projects";
    };
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
    magic-wormhole.enable = true;
    starship.enable = true;
    tmux.enable = true;
    zoxide.enable = true;
    zsh.enable = true;
  };

  programs.fish = {
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

  programs.vscode = {
    enable = true;
    profiles.default = {
      enableUpdateCheck = false;
      userSettings = {
        "files.autoDelay" = 100;
        "files.autoSave" = "afterDelay";
        "files.refactoring.autoSave" = true;
        "[nix]"."editor.tabSize" = 2;
        "workbench.iconTheme" = "vira-icons-deepforest";
        "workbench.colorTheme" = "Vira Deepforest";
        "workbench.sideBar.location" = "right";
      };

      extensions = with pkgs.vscode-extensions;
        [
          kamadorueda.alejandra
          jnoortheen.nix-ide
          usernamehw.errorlens
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "Kilo-Code";
            publisher = "kilocode";
            version = "4.121.2";
            sha256 = "sha256-pTCcZ+295f/I/sLileXYKtTQ2m11lR4RYhYoplk8Ing=";
          }
          {
            name = "vsc-vira-theme";
            publisher = "vira";
            version = "2025.10.4";
            sha256 = "sha256-oM/r2RyblHeNg02yu2+lGzp44Z+vPR01QxY8ePvaTf4=";
          }
        ];
    };
  };
}
