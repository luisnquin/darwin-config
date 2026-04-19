{
  flake.modules.homeManager.aiLiteLLM = {config, ...}: let
    ollamaApiBase = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
    litellmOllamaModels =
      map (model: {
        model_name = model;
        litellm_params = {
          model = "ollama/${model}";
          api_base = ollamaApiBase;
        };
      })
      config.services.ollama.loadModels
      ++ [
        {
          model_name = "ollama/*";
          litellm_params = {
            model = "ollama/*";
            api_base = ollamaApiBase;
          };
        }
      ];
  in {
    services.litellm = {
      enable = true;
      host = "0.0.0.0";
      port = 4000;

      settings = {
        model_list = litellmOllamaModels;

        general_settings = {
          master_key = "dummy";
        };

        litellm_settings = {
          check_provider_endpoint = true;
          drop_params = true;
          set_verbose = false;
        };
      };
    };
  };
}
