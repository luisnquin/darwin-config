{inputs, ...}: {
  flake.modules.homeManager.luisnquin = {
    imports =
      [inputs.zen-browser.homeModules.default]
      ++ (with inputs.self.modules.homeManager; [
        android
        browser
        cli
        ext
        extOptions
        fish
        git
        knownHosts
        macos
        node
        packages
        sickdeck
        sickdeckOptions
        ssh
        tmux
        user
      ]);
  };
}
