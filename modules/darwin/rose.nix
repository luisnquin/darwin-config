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
      menuBar
      minisim
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
