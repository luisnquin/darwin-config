{
  flake.modules.darwin.networking = {
    networking = {
      hostName = "dyx";
      knownNetworkServices = [
        "Wi-Fi"
        "Ethernet Adaptor"
        "Thunderbolt Ethernet"
      ];
    };
  };
}
