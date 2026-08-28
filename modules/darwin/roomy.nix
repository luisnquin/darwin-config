{
  flake.modules.darwin.roomy = {
    imports = [../../pkgs/roomy/darwin-modules];

    programs.roomy.enable = true;
  };
}
