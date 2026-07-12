{
  flake.modules.homeManager.macos = {
    targets.darwin = {
      # copy real .app bundles so Spotlight/Launchpad index them
      copyApps.enable = true;
      # linkApps defaults to on for stateVersion < 25.11 and conflicts with copyApps
      linkApps.enable = false;
    };
  };
}
