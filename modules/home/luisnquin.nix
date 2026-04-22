{inputs, ...}: {
  flake.modules.homeManager.luisnquin = {
    imports = with inputs.self.modules.homeManager; [
      cli
      fish
      git
      knownHosts
      node
      packages
      ssh
      tmux
      user
    ];
  };
}
