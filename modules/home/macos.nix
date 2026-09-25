{
  flake.modules.homeManager.macos = {
    # home-manager stopped shipping its own man on darwin, so the index it
    # would build is dead weight; /usr/bin/man still finds profile pages by
    # walking PATH. Only apropos loses its index.
    programs.man.generateCaches = false;

    targets.darwin = {
      # copy real .app bundles so Spotlight/Launchpad index them; symlinked
      # bundles are invisible to both, and the two targets conflict
      copyApps.enable = true;
      linkApps.enable = false;
    };

    launchd.agents.sponsorbar = {
      enable = true;
      config = {
        ProgramArguments = [
          "/Applications/SponsorBar.app/Contents/MacOS/SponsorBar"
        ];
        ProcessType = "Interactive";
        RunAtLoad = true;
      };
    };
  };
}
