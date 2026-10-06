{
  flake.overlays.sponsorbar-hover = final: _prev: {
    sponsorbar-hover = final.callPackage ../../pkgs/sponsorbar-hover {};
  };
}
