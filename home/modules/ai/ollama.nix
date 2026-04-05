{
  services.ollama = {
    enable = true;
    loadModels = [
      "gemma4:e4b"
    ];
    syncModels = true;
  };
}
