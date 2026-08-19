{
  flake.overlays.minisim = final: _prev: {
    # Order matters: two-line-device-rows patches createMenuItem, whose context
    # already carries the `platform:` argument colored-device-icons introduces.
    minisim = (final.callPackage ../../pkgs/third-party/minisim {}).overrideAttrs (old: {
      patches =
        (old.patches or [])
        ++ [
          ./patches/minisim/colored-device-icons.patch
          ./patches/minisim/two-line-device-rows.patch
        ];
    });
  };
}
