{
  flake.modules.homeManager.aiOllama = {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      port = 11434;
      loadModels = [
        "gemma4:e4b"
        "qwen2.5-coder:7b"
      ];
      syncModels = true;
    };
  };
}
