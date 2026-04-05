{
  services.ollama = {
    enable = true;
    loadModels = [
      "gemma4:e4b"
      "qwen2.5-coder:7b"
    ];
    syncModels = true;
  };
}
