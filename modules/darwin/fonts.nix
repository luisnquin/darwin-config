{pkgs, ...}: {
  flake.modules.darwin.fonts = {
    fonts = {
      fontDir.enable = true;
      fonts = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
      ];
    };
  };
}
