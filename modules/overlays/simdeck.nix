{
  # SimDeck publishes prebuilt, Apple-codesigned Mach-O binaries in its npm
  # tarball, so there is nothing to compile here; a source build would instead
  # need Rust plus a static x264. The shipped arm64 binary links only system
  # frameworks (Foundation, AVFoundation, VideoToolbox, ...), so the runtime
  # closure is just node.
  flake.overlays.simdeck = final: prev: {
    simdeck = final.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "simdeck";
      version = "0.1.33";

      src = final.fetchurl {
        url = "https://registry.npmjs.org/simdeck/-/simdeck-${finalAttrs.version}.tgz";
        hash = "sha256-IvXd7AT7AysTj+KUrtJeDtGN2rIjxdg5ChYRqvbOzFs=";
      };

      nativeBuildInputs = [final.makeWrapper];

      # Stripping rewrites the Mach-O and invalidates the Apple signature, which
      # on arm64 macOS is a hard SIGKILL at exec, not a warning.
      dontStrip = true;

      # The server derives its client root from the binary as
      # `current_exe/../../packages/client/dist`, and the JS launcher walks up
      # for `build/simdeck-bin`. Both need the published layout kept intact, so
      # the tree is installed whole and only the launcher is exposed in bin/.
      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/simdeck $out/bin
        cp -R . $out/lib/simdeck

        makeWrapper ${final.nodejs_26}/bin/node $out/bin/simdeck \
          --add-flags $out/lib/simdeck/packages/cli/bin/simdeck.mjs

        runHook postInstall
      '';

      meta = {
        description = "Drive iOS Simulators and Android emulators from an IDE or CLI";
        homepage = "https://simdeck.sh";
        license = final.lib.licenses.asl20;
        mainProgram = "simdeck";
        platforms = final.lib.platforms.darwin;
        sourceProvenance = [final.lib.sourceTypes.binaryNativeCode];
      };
    });
  };
}
