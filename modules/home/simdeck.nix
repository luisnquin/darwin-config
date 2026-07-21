{
  flake.modules.homeManager.simdeck = {
    osConfig,
    pkgs,
    ...
  }: let
    port = 4310;

    advertiseHost = osConfig.networking.hostName;

    simdeckServiceProvision = pkgs.writeShellApplication {
      name = "simdeck-service-provision";
      runtimeInputs = [pkgs.simdeck];
      text = ''
        simdeck service reset --bind 0.0.0.0 --advertise-host ${advertiseHost}
      '';
    };
  in {
    home = {
      packages = [pkgs.simdeck simdeckServiceProvision];

      file.".simdeck/config.json".text = builtins.toJSON {service = {inherit port;};};
    };
  };
}
