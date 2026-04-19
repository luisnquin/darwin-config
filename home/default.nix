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

    file.".ssh/known_hosts".text = let
      mkLine = host: key: "${host} ssh-${key.type} ${key.key}";
      mkLines = host: keys: map (mkLine host) keys;
    in
      pkgs.lib.concatStringsSep "\n" (pkgs.lib.flatten (pkgs.lib.mapAttrsToList mkLines {
        "github.com" = [
          {
            type = "ed25519";
            key = "AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
          }
          {
            type = "rsa";
            key = "AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
          }
        ];
      }))
      + "\n";

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
      package = pkgs.lib.hiPrio pkgs.nodejs_25;
    };

    password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };

        mac-local = {
          hostname = "dyx.local";
        };

        mac = {
          hostname = "dyx";
        };
      };
    };
  };
}
