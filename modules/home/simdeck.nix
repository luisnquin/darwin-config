{
  flake.modules.homeManager.simdeck = {
    osConfig,
    pkgs,
    ...
  }: let
    port = 4310;

    advertiseHost = osConfig.networking.hostName;

    skill = pkgs.fetchurl {
      name = "simdeck-skill.md";
      url = "https://raw.githubusercontent.com/NativeScript/SimDeck/8baf1037ece3b37a90bb3040335a9a1283c0b2b5/skills/simdeck/SKILL.md";
      hash = "sha256-VY1IfDIYhGLymhMMhvC8qG2EeNevqGUwdzXbyKqjWHQ=";
    };

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

      file = {
        ".simdeck/config.json".text = builtins.toJSON {service = {inherit port;};};

        ".claude/skills/simdeck/SKILL.md".source = skill;
        ".codex/skills/simdeck/SKILL.md".source = skill;
      };
    };
  };
}
