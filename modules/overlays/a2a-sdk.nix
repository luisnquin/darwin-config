{
  # a2a-sdk's e2e push-notification tests pickle a FastAPI app across a
  # subprocess; newer FastAPI made `openapi` a local closure that can't be
  # pickled, so they error out. nixpkgs already disables these tests, but
  # gates it on python >= 3.14 while litellm here builds a2a-sdk with python
  # 3.13, where the same failure happens. Broaden the skip to cover 3.13.
  flake.overlays.a2a-sdk = final: prev: {
    pythonPackagesExtensions =
      (prev.pythonPackagesExtensions or [])
      ++ [
        (pyfinal: pyprev: {
          a2a-sdk = pyprev.a2a-sdk.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or []) ++ ["test_notification_triggering"];
          });
        })
      ];
  };
}
