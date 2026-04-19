{
  flake.modules.homeManager.litellmOptions = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types;

    cfg = config.services.litellm;
    settingsFormat = pkgs.formats.yaml {};
    configFile = settingsFormat.generate "litellm-config.yaml" cfg.settings;
  in {
    options = {
      services.litellm = {
        enable = lib.mkEnableOption "LiteLLM server";
        package = lib.mkPackageOption pkgs "litellm" {};

        stateDir = lib.mkOption {
          type = types.path;
          default = "${config.home.homeDirectory}/Library/Application Support/litellm";
          description = "LiteLLM state and logs directory.";
        };

        host = lib.mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Listen host address.";
        };

        port = lib.mkOption {
          type = types.port;
          default = 8080;
          description = "Listen port.";
        };

        settings = lib.mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;
            options = {
              model_list = lib.mkOption {
                type = settingsFormat.type;
                default = [];
              };
            };
          };
          default = {};
          description = "LiteLLM YAML configuration.";
        };

        environment = lib.mkOption {
          type = types.attrsOf types.str;
          default = {
            SCARF_NO_ANALYTICS = "True";
            DO_NOT_TRACK = "True";
            ANONYMIZED_TELEMETRY = "False";
          };
          description = "Environment variables.";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      home.activation.createLiteLLMDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${cfg.stateDir}"
      '';

      launchd.agents.litellm = {
        enable = true;
        config = {
          ProgramArguments = [
            "${lib.getExe cfg.package}"
            "--host"
            "${cfg.host}"
            "--port"
            "${toString cfg.port}"
            "--config"
            "${configFile}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          WorkingDirectory = cfg.stateDir;
          StandardOutPath = "${cfg.stateDir}/stdout.log";
          StandardErrorPath = "${cfg.stateDir}/stderr.log";
          EnvironmentVariables = cfg.environment;
        };
      };
    };
  };
}
