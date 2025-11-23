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
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # disable greeting
      '';
      plugins = [
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
    zsh.enable = true;
    ghostty = {
      enable = true;
      package = null;
      enableFishIntegration = true;
      settings = {
        theme = "Iceberg Dark";
        cursor-style = "bar";
        cursor-style-blink = "true";
        font-synthetic-style = "bold";

        background-opacity = "0.8";
        link-url = "true";
        working-directory = "home";

        window-padding-x = "15,4";
        window-padding-y = "8,6";
        window-vsync = "false";
        window-save-state = "never";

        clipboard-read = "allow";
        clipboard-write = "allow";

        clipboard-trim-trailing-spaces = "true";
        clipboard-paste-protection = "true";
        shell-integration = "fish";
        desktop-notifications = "true";
        auto-update = "off";
      };
    };
    starship = {
      enable = true;
      enableFishIntegration = true;
      enableInteractive = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 400;
        scan_timeout = 30;
        character = {
          success_symbol = "[](bold green)";
          error_symbol = "[](bold red)";
        };
        format = pkgs.lib.concatStrings [
          "$sudo"
          "$directory"
          "$hostname"
          "$git_branch"
          "$git_state"
          "$git_metrics"
          "\${custom.git_remote_diff}"
          "$c"
          "$nodejs"
          "$go"
          "$nix_shell"
          "\${custom.dotfiles_workspace}"
          "\n$character"
        ];

        cmd_duration = {
          min_time = 200;
          show_milliseconds = false;
          format = "it took [$duration]($style) ";
        };

        directory = {
          truncation_length = 2;
          truncate_to_repo = false;
          read_only = "";
          read_only_style = "#454343";
          style = "#8d3beb";
        };

        hostname = {
          ssh_only = false;
          ssh_symbol = "🌐 ";
          format = "\\[[$hostname](bold #db2c75)\\] ";
          trim_at = ".local";
          disabled = false;
        };

        custom.git_remote_diff = {
          description = "Displays the number of commits ahead of the remote";
          shell = ["bash" "--noprofile" "--norc"];
          format = "[$symbol $output]($style) ";
          symbol = "";
          style = "#5941f2";
          command = ''
            branch=$(git rev-parse --abbrev-ref HEAD)

            if git rev-parse --is-inside-work-tree > /dev/null; then
              ahead=$(git rev-list --count origin/$branch..HEAD)

              if [ "$ahead" -gt 0 ]; then
                echo "$ahead?"
              fi
            fi
          '';
          when = ''
            git rev-parse --is-inside-work-tree > /dev/null &&
            [ "$(git rev-list --count origin/$(git rev-parse --abbrev-ref HEAD)..HEAD)" -gt 0 ]
          '';
        };
      };
    };
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
