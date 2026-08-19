{
  flake.overlays.lix = _final: prev: {
    # Lix hands every darwin builder a sandbox profile no matter what: `sandbox
    # = false` only swaps the full profile for `sandbox-minimal.sb`, and
    # `__noChroot` is never consulted on that path. macOS then refuses to apply
    # a second profile on top of it, so a builder that sandboxes itself cannot
    # run inside a nix build at all. The patch lets a derivation opt out of the
    # minimal profile with `__noChroot`, which is what `pkgs.minisim` needs for
    # SwiftPM to compile its remote manifests.
    lix = prev.lix.overrideAttrs (old: {
      # The functional suite does not survive being run from a nix build on this
      # host: two source builds failed two different tests (`functional-remote-store`
      # and `functional-nix-shell-basic`), and the first of those was an unpatched
      # control. The unit tests still run.
      doInstallCheck = false;

      patches =
        (old.patches or [])
        ++ [
          ./patches/lix/darwin-no-chroot-skips-minimal-sandbox.patch
        ];
    });
  };
}
