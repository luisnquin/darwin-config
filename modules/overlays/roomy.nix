{
  flake.overlays.roomy = final: _prev: {
    roomy = final.callPackage ../../pkgs/roomy {};
  };
}
