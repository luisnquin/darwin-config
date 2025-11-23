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
