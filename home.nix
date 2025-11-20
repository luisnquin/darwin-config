{pkgs, ...}: {
  programs.zen-browser.enable = true;

  home = {
    stateVersion = "25.05";
    username = "luisnquin";
    homeDirectory = "/Users/luisnquin";
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    alejandra
  ];

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      kamadorueda.alejandra
      jnoortheen.nix-ide
      usernamehw.errorlens
    ];
  };
}
