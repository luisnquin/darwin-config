{inputs, ...}: {
  flake.modules.darwin.rose = {
    imports = with inputs.self.modules.darwin; [
      dock
      dockOptions
      environment
      fish
      fonts
      homebrew
      iphone
      networking
      nix
      openssh
      power
      shared
      tailscale
      userActivation
      users
      defaults
    ];
  };
}
