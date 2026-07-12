{inputs, ...}: {
  flake.modules.homeManager.luisnquin = {
    imports = with inputs.self.modules.homeManager; [
      aiLiteLLM
      aiOllama
      browser
      cli
      fish
      git
      knownHosts
      litellmOptions
      macos
      node
      ollamaOptions
      packages
      ssh
      tmux
      user
    ];
  };
}
