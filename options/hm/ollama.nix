{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types getExe mkForce;

  cfg = config.services.ollama;

  ollamaPackage =
    if cfg.acceleration == null
    then cfg.package
    else if cfg.acceleration == false
    then pkgs.ollama-cpu
    else pkgs."ollama-${cfg.acceleration}";

  modelLoaderScript = let
    ollama = getExe ollamaPackage;
    parallel = getExe pkgs.parallel;
    awk = getExe pkgs.gawk;
    sed = getExe pkgs.gnused;

    declaredModelsRegex = lib.pipe cfg.loadModels [
      (map lib.escapeRegex)
      (lib.concatStringsSep "|")
      (lib.escape ["/"])
      lib.escapeShellArg
    ];
  in
    pkgs.writeShellScript "ollama-model-manager" ''
      set -euo pipefail

      until ${pkgs.curl}/bin/curl -s http://${cfg.host}:${toString cfg.port}/api/tags > /dev/null; do
        sleep 2
      done

      ${lib.optionalString cfg.syncModels ''
        installed=$('${ollama}' list | '${awk}' 'NR > 1 {print $1}')
        ${
          if (cfg.loadModels != [])
          then ''
            undeclared=$(echo "$installed" | '${sed}' -E /${declaredModelsRegex}/d)
          ''
          else ''
            undeclared="$installed"
          ''
        }
        if [ -n "$undeclared" ]; then
          for model in $undeclared; do
            '${ollama}' rm "$model"
          done
        fi
      ''}

      if [ -n "${lib.concatStringsSep " " cfg.loadModels}" ]; then
        '${parallel}' --tag '${ollama}' pull ::: ${lib.escapeShellArgs cfg.loadModels}
      fi
    '';
in {
  options.services.ollama = {
    home = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.ollama";
    };

    models = mkOption {
      type = types.str;
      default = "${cfg.home}/models";
    };

    loadModels = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    syncModels = mkOption {
      type = types.bool;
      default = false;
    };

    rocmOverrideGfx = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ollamaPackage];

    launchd.agents.ollama = {
      enable = true;
      config = mkForce {
        # Added Label to satisfy launchd requirement
        Label = "org.nix-community.ollama";
        ProgramArguments = [(getExe ollamaPackage) "serve"];
        WorkingDirectory = cfg.home;
        StandardErrorPath = "${cfg.home}/ollama.err.log";
        StandardOutPath = "${cfg.home}/ollama.out.log";
        EnvironmentVariables =
          cfg.environmentVariables
          // {
            HOME = cfg.home;
            OLLAMA_MODELS = cfg.models;
            OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
          }
          // lib.optionalAttrs (cfg.rocmOverrideGfx != null) {
            HSA_OVERRIDE_GFX_VERSION = cfg.rocmOverrideGfx;
          };
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
      };
    };

    launchd.agents.ollama-model-loader = mkIf (cfg.loadModels != [] || cfg.syncModels) {
      enable = true;
      config = {
        Label = "org.nix-community.ollama-model-loader";
        ProgramArguments = ["${modelLoaderScript}"];
        EnvironmentVariables = config.launchd.agents.ollama.config.EnvironmentVariables;
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
      };
    };
  };
}
