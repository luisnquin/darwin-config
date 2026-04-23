{
  flake.modules.darwin.networking = {
    networking = {
      hostName = "rose";
      knownNetworkServices = [
        "Wi-Fi"
        "Ethernet Adaptor"
        "Thunderbolt Ethernet"
      ];
    };
  };
}
