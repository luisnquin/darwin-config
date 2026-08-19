{
  flake.overlays.minisim = final: prev: {
    minisim = final.callPackage ../../pkgs/third-party/minisim {};
  };
}
