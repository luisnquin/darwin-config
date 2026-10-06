{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sponsorbar-hover;
in {
  options.services.sponsorbar-hover = {
    enable = lib.mkEnableOption "periodic SponsorBar hover while idle";
    package = lib.mkPackageOption pkgs "sponsorbar-hover" {};
  };

  config = lib.mkIf cfg.enable {
    launchd.agents.sponsorbar-hover = {
      enable = true;
      config = {
        ProgramArguments = ["${lib.getExe cfg.package}"];
        ProcessType = "Background";
        RunAtLoad = true;
        StartInterval = 540;
      };
    };
  };
}
