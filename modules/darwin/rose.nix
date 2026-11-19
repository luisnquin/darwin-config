{inputs, ...}: {
  flake.modules.darwin.rose = {
    imports = with inputs.self.modules.darwin; [
      dock
      dockOptions
      environment
      ext
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
      roomy
      shared
      signedApps
      tailscale
      userActivation
      users
      defaults
    ];
  };
}
