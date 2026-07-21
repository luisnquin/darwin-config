{inputs, ...}: {
  flake.modules.homeManager.luisnquin = {
    imports =
      [inputs.zen-browser.homeModules.default]
      ++ (with inputs.self.modules.homeManager; [
        aiLiteLLM
        aiOllama
        android
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
      ]);
  };
}
