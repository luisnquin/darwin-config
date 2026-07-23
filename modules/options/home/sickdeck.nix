{
  flake.modules.homeManager.sickdeckOptions = {
    config,
    lib,
    osConfig,
    pkgs,
    ...
  }: let
    inherit (lib) types;

    cfg = config.services.sickdeck;

    # launchd gets the native binary, not `bin/sickdeck` (a node launcher that
    # would only re-exec it). The server resolves its client root as
    # `current_exe/../../packages/client`, but it is passed explicitly so the
    # agent does not depend on that inference holding.
    binary = "${cfg.package}/lib/sickdeck/build/sickdeck-bin";
    clientRoot = "${cfg.package}/lib/sickdeck/packages/client/dist";

    tailscale = lib.getExe' osConfig.services.tailscale.package "tailscale";
  in {
    options = {
      services.sickdeck = {
        enable = lib.mkEnableOption "SickDeck device service";
        package = lib.mkPackageOption pkgs "sickdeck" {};

        port = lib.mkOption {
          type = types.port;
          default = 4310;
          description = "Listen port.";
        };

        bind = lib.mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = ''
            Listen address. The tailnet address would be tighter but is not
            known at evaluation time; what keeps the service private is the
            identity check, not the bind address.
          '';
        };

        advertiseHost = lib.mkOption {
          type = types.str;
          default = osConfig.networking.hostName;
          description = "Host the service hands out in pairing and stream URLs.";
        };

        allowedLogins = lib.mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["luisnquin@github"];
          description = ''
            Tailnet logins allowed to reach the API, as reported by
            `tailscale whois`. Empty allows any peer tailscaled can identify.
          '';
        };

        logDir = lib.mkOption {
          type = types.path;
          default = "${config.home.homeDirectory}/Library/Logs";
          description = ''
            Where the agent writes its logs. Matches the paths the binary
            reports in `sickdeck service status`.
          '';
        };

        environment = lib.mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = ''
            Extra environment for the agent. Never put a credential here: the
            plist is generated into the world-readable nix store.
          '';
        };
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = osConfig.services.tailscale.enable;
          message = ''
            services.sickdeck authorizes callers by their tailnet identity, so
            it needs a local tailscaled to ask. Enable services.tailscale.
          '';
        }
      ];

      home = {
        packages = [cfg.package];

        # `~/.simdeck` is a protected token in the fork's rename pass — the
        # state directory keeps the name existing state and upstream binaries
        # use. The port is repeated here because the CLI falls back to it when
        # no service is installed yet.
        file.".simdeck/config.json".text = builtins.toJSON {
          service = {inherit (cfg) port;};
        };
      };

      # The label is the one the binary itself manages, so `service status`,
      # `kill` and `killall` still see this agent, and a service provisioned by
      # an older binary is replaced rather than duplicated.
      launchd.agents.sickdeck = {
        enable = true;
        config = {
          Label = "org.nativescript.simdeck";
          # No --access-token and no --pairing-code: in tailnet mode the server
          # generates neither, which is what makes a store-generated plist safe
          # to publish. The remaining flags mirror the ones the binary writes
          # itself, so `sickdeck service start` reuses this agent instead of
          # replacing it.
          ProgramArguments = [
            binary
            "service"
            "run"
            "--port"
            (toString cfg.port)
            "--bind"
            cfg.bind
            "--client-root"
            clientRoot
            "--video-codec"
            "auto"
            "--android-gpu"
            "host"
            "--server-kind"
            "launch-agent"
            "--advertise-host"
            cfg.advertiseHost
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${cfg.logDir}/sickdeck.log";
          StandardErrorPath = "${cfg.logDir}/sickdeck.err.log";
          EnvironmentVariables =
            {
              SIMDECK_AUTH = "tailnet";
              SIMDECK_TAILNET_LOGINS = lib.concatStringsSep "," cfg.allowedLogins;
              # A launchd agent gets a minimal PATH, and tailscale is not on it.
              SIMDECK_TAILSCALE_BINARY = tailscale;
            }
            // cfg.environment;
        };
      };
    };
  };
}
