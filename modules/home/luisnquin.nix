{inputs, ...}: {
  flake.modules.homeManager.luisnquin = {
    imports = with inputs.self.modules.homeManager; [
      aiLiteLLM
      aiOllama
      cli
      fish
      git
      knownHosts
      litellmOptions
      node
      ollamaOptions
      packages
      passwordStore
      ssh
      tmux
      user
      zenBrowser
    ];
  };
}
