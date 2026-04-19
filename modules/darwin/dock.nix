{
  flake.modules.darwin.dock = {config, ...}: {
    local.dock = rec {
      enable = true;
      username = config.system.primaryUser;
      entries = let
        mkHomeAppPath = appName: "/Users/${username}/Applications/Home Manager Apps/${appName}";
      in [
        {path = "/System/Applications/App Store.app";}
        {path = mkHomeAppPath "Zen Browser (Beta).app";}
        {path = "/Applications/Ghostty.app/";}
        {path = "/Applications/Notion.app";}
        {path = "/Applications/Google Chrome.app/";}
        {path = "/Users/${username}/Applications/Autodesk Fusion.app";}
      ];
    };
  };
}
