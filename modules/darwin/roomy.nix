{inputs, ...}: {
  flake.modules.darwin.roomy = {config, ...}: let
    inherit (inputs.self.lib) ext;
  in {
    imports = [../../pkgs/roomy/darwin-modules];

    local.signedApps.Roomy = {
      source = "${config.programs.roomy.package}/Applications/Roomy.app";
      agent = "roomy";
    };

    programs.roomy = {
      enable = true;
      app = "/Applications/Roomy.app";

      # Half of what Roomy measures lives on the external volume now, and only
      # these variables say so.
      sessionEnvironment = config.local.ext.guiEnvScript;

      extraVolumes = [ext.path];
      scratchDirs = map (dir: "${ext.path}/scratch/${dir}") ["squad" "qa"];
    };
  };
}
