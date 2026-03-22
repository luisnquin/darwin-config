{
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
      enable = lib.mkEnableOption "servidor LiteLLM";
      package = lib.mkPackageOption pkgs "litellm" {};

      stateDir = lib.mkOption {
        type = types.path;
        default = "${config.home.homeDirectory}/Library/Application Support/litellm";
        description = "Directorio de estado y logs de LiteLLM.";
      };

      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Dirección host de escucha.";
      };

      port = lib.mkOption {
        type = types.port;
        default = 8080;
        description = "Puerto de escucha.";
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
        description = "Configuración YAML de LiteLLM.";
      };

      environment = lib.mkOption {
        type = types.attrsOf types.str;
        default = {
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";
        };
        description = "Variables de entorno.";
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
}
