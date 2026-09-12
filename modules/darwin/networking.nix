{
  flake.modules.darwin.networking = {
    networking = {
      hostName = "rose";

      # Must match `networksetup -listallnetworkservices`; unknown names are skipped silently.
      knownNetworkServices = [
        "Ethernet"
        "Thunderbolt Bridge"
        "Wi-Fi"
      ];

      applicationFirewall = {
        enable = true;
        blockAllIncoming = false;
        enableStealthMode = true;
      };
    };
  };
}
