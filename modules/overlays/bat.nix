{
  flake.overlays.bat = _final: prev: {
    bat = prev.bat.overrideAttrs (old: {
      patches =
        (old.patches or [])
        ++ [
          ./patches/bat/idempotent-cache-build.patch
        ];
    });
  };
}
