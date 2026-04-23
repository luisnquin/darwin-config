{pkgs, ...}: {
  flake.modules.darwin.fonts = {
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];
  };
}
