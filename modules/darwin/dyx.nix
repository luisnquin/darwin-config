{inputs, ...}: {
  flake.modules.darwin.dyx = {
    imports = with inputs.self.modules.darwin; [
      dock
      dockOptions
      environment
      fish
      homebrew
      networking
      nix
      openssh
      power
      shared
      tailscale
      users
    ];
  };
}
