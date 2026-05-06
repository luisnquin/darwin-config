{
  flake.modules.darwin.dock = {config, ...}: {
    local.dock = {
      enable = true;
      username = config.system.primaryUser;
      entries = [
        {path = "/System/Applications/App Store.app";}
        {path = "/Applications/Safari.app/";}
        {path = "/System/Applications/System Settings.app";}
        {path = "/Applications/Ghostty.app/";}
      ];
    };
  };
}
