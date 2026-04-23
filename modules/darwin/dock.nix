{
  flake.modules.darwin.dock = {config, ...}: {
    local.dock = {
      enable = true;
      username = config.system.primaryUser;
      entries = [
        {path = "/System/Applications/App Store.app";}
        {path = "/Applications/Ghostty.app/";}
      ];
    };
  };
}
