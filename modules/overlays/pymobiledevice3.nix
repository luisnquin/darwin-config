{
  # pyimg4 0.8.8 pins asn1<3.0.0 and its test suite fails against asn1 3.x,
  # which is why nixpkgs marks it broken and pymobiledevice3 won't build.
  # Only ipsw-parser (firmware image parsing) pulls it in; the screenshot
  # path never runs the incompatible code, so relaxing the bound and skipping
  # its tests is enough to get a working pymobiledevice3.
  flake.overlays.pymobiledevice3 = final: prev: {
    pythonPackagesExtensions =
      (prev.pythonPackagesExtensions or [])
      ++ [
        (pyfinal: pyprev: {
          pyimg4 = pyprev.pyimg4.overridePythonAttrs (old: {
            pythonRelaxDeps = (old.pythonRelaxDeps or []) ++ ["asn1"];
            doCheck = false;
            meta = (old.meta or {}) // {broken = false;};
          });
        })
      ];
  };
}
