{inputs, ...}: {
  flake.modules.darwin.rose = {
    imports = with inputs.self.modules.darwin; [
      dock
      dockOptions
      environment
      fish
      fonts
      homebrew
      networking
      nix
      openssh
      power
      shared
      tailscale
      users
      defaults
    ];
  };
}
