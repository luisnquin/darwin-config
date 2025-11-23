{pkgs, ...}: {
  programs.zen-browser.enable = true;

  home = {
    stateVersion = "25.05";
    username = "luisnquin";
    homeDirectory = "/Users/luisnquin";
  };

  nixpkgs.config.allowUnfree = true;

  home = {
    packages = with pkgs; [
      notion-app
      alejandra
      lazygit
      nodejs
      bun
    ];

    shellAliases = {
      "pr" = "cd ~/Projects";
      "lg" = "lazygit";
    };
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
    fzf = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      colors = {
        "fg" = "#e8d4f3";
        "fg+" = "#d0d0d0";
        "bg" = "-1";
        "bg+" = "#221326";
        "hl" = "#4eb0d0";
        "hl+" = "#4eb8dc";

        "spinner" = "#af5fff";
        "marker" = "#782cce";
        "prompt" = "#3d848b";
        "pointer" = "#af5fff";
        "header" = "#87afaf";
        "info" = "#d2d286";

        "border" = "#262626";
        "query" = "#d9d9d9";
        "label" = "#aeaeae";
      };

      defaultOptions = [
        "--border=rounded"
        "--preview-window=border-rounded"
        "--prompt='> '"
        "--marker='>'"
        "--pointer='◆'"
        "--separator='─'"
        "--scrollbar='│'"
      ];
    };
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
      };

      extensions = with pkgs.vscode-extensions; [
        kamadorueda.alejandra
        jnoortheen.nix-ide
        usernamehw.errorlens
      ];
    };
  };
}
