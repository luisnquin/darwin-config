{
  flake.modules.darwin.dock = {config, ...}: {
    local.dock = {
      enable = true;
      username = config.system.primaryUser;
      entries = [
        {path = "/System/Applications/App Store.app";}
        {path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/";}
        {path = "/System/Applications/System Settings.app";}
        {path = "/Applications/Ghostty.app/";}
        {path = "/System/Applications/Calendar.app/";}
        {path = "/Applications/Nix Apps/OpenDeviceHub.app/";}
      ];
    };
  };
}
