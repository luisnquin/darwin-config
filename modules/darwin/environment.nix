{
  flake.modules.darwin.environment = {pkgs, ...}: {
    environment = {
      systemPackages = with pkgs; [
        vim
        nano # replace default editor
        rsync # v3
      ];

      variables = {
        LANG = "en_US.UTF-8";
      };
    };
  };
}
