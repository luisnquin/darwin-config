{
  flake.modules.darwin.roomy = {config, ...}: {
    imports = [../../pkgs/roomy/darwin-modules];

    programs.roomy = {
      enable = true;

      # Half of what Roomy measures lives on the external volume now, and only
      # these variables say so.
      sessionEnvironment = config.local.ext.guiEnvScript;
    };
  };
}
