{
  flake.overlays.simdeck = final: prev: let
    version = "0.1.33";

    src = final.fetchFromGitHub {
      owner = "NativeScript";
      repo = "SimDeck";
      rev = "simdeck-v${version}";
      hash = "sha256-0x+DUKUR/WIujCpcXcoRRr8vmY2D7q62xSzoCZZ77K8=";
    };

    # build.rs `-force_load`s a static x264. nixpkgs' `enableShared = false` is
    # broken on its own: makeFlags hardcodes `install-lib-shared`, so the `lib`
    # output is never populated.
    x264Static = (final.x264.override {enableShared = false;}).overrideAttrs (_: {
      outputs = ["out" "dev"];
      makeFlags = [
        "BASHCOMPLETIONSDIR=$(out)/share/bash-completion/completions"
        "install-bashcompletion"
        "install-lib-static"
      ];
    });

    server = final.rustPlatform.buildRustPackage {
      pname = "simdeck-server";
      inherit version src;

      cargoLock.lockFile = "${src}/packages/server/Cargo.lock";
      sourceRoot = "source/packages/server";

      nativeBuildInputs = [final.pkg-config];
      # XCWH264Encoder.m uses VideoToolbox keys absent from the default 14.4 SDK.
      buildInputs = [x264Static final.apple-sdk_26];

      doCheck = false;
    };

    devtoolsFrontend = final.fetchurl {
      url = "https://registry.npmjs.org/@react-native/debugger-frontend/-/debugger-frontend-0.85.2.tgz";
      hash = "sha512-j+0b9H5f5hGTLQxHIhJU/b/W6ijuxJF+ZTLHB0se2kzUBNxFKd7DkIc6753qk3CJdiv55vxG3XDgmlpbHxOpmA==";
    };

    client = final.buildNpmPackage {
      pname = "simdeck-client";
      inherit version src;

      sourceRoot = "source/packages/client";
      npmDepsHash = "sha256-MtpXAMK2rqUPD829fWDralP6AkizwhrKboYZB85l80M=";

      # build-client.sh overlays the debugger UI onto the Vite bundle, taking it
      # from the root workspace's node_modules.
      postBuild = ''
        mkdir -p dist/chrome-devtools-ui "$TMPDIR/devtools"
        tar -xzf ${devtoolsFrontend} -C "$TMPDIR/devtools"
        cp -R "$TMPDIR"/devtools/package/dist/third-party/front_end/. dist/chrome-devtools-ui/
      '';

      installPhase = ''
        runHook preInstall
        cp -R dist $out
        runHook postInstall
      '';
    };

    # index.ts annotates node globals, so tsc needs the ambient declarations
    # despite the package having no runtime dependencies.
    typesNode = final.fetchurl {
      url = "https://registry.npmjs.org/@types/node/-/node-22.19.17.tgz";
      hash = "sha512-wGdMcf+vPYM6jikpS/qhg6WiqSV/OhG+jeeHT/KlVqxYfD40iYJf9/AE1uQxVWFvU7MipKRkRv8NSHiCGgPr8Q==";
    };

    undiciTypes = final.fetchurl {
      url = "https://registry.npmjs.org/undici-types/-/undici-types-6.21.0.tgz";
      hash = "sha512-iwDZqg0QAGrg9Rav5H4n0M64c3mkR59cJ6wQp+7C4nI0gsmExaedaYLNO44eT4AtBBwjbTiGPMlt2Md0T9H9JQ==";
    };

    simdeckTest = final.stdenvNoCC.mkDerivation {
      pname = "simdeck-test";
      inherit version src;

      sourceRoot = "source/packages/simdeck-test";
      nativeBuildInputs = [final.typescript];

      preBuild = ''
        mkdir -p node_modules/@types/node node_modules/undici-types
        tar -xzf ${typesNode} -C node_modules/@types/node --strip-components=1
        tar -xzf ${undiciTypes} -C node_modules/undici-types --strip-components=1
      '';

      buildPhase = ''
        runHook preBuild
        tsc -p tsconfig.json
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp -R dist $out
        runHook postInstall
      '';
    };
  in {
    simdeck = final.stdenvNoCC.mkDerivation {
      pname = "simdeck";
      inherit version src;

      nativeBuildInputs = [final.makeWrapper];

      dontBuild = true;

      # The launcher walks parents for `build/simdeck-bin` and the server
      # resolves its client root as `current_exe/../../packages/client`, so this
      # layout cannot be flattened.
      installPhase = ''
        runHook preInstall

        root=$out/lib/simdeck
        mkdir -p "$root/build" "$root/packages/cli" "$root/packages/client" \
          "$root/packages/simdeck-test" "$root/scripts"

        cp package.json LICENSE README.md "$root/"
        cp -R packages/cli/bin "$root/packages/cli/"
        cp -R scripts/experimental "$root/scripts/"
        cp scripts/studio-host-provider.mjs scripts/studio-provider-bridge.mjs \
          scripts/postinstall.mjs "$root/scripts/"

        cp -R ${client} "$root/packages/client/dist"
        cp -R ${simdeckTest} "$root/packages/simdeck-test/dist"

        install -m755 ${server}/bin/simdeck-server "$root/build/simdeck-bin"
        ln -s simdeck-bin "$root/build/simdeck-bin-darwin-arm64"

        makeWrapper ${final.nodejs_26}/bin/node $out/bin/simdeck \
          --add-flags "$root/packages/cli/bin/simdeck.mjs"

        runHook postInstall
      '';

      meta = {
        description = "Drive iOS Simulators and Android emulators from an IDE or CLI";
        homepage = "https://simdeck.sh";
        license = final.lib.licenses.asl20;
        mainProgram = "simdeck";
        platforms = ["aarch64-darwin"];
        sourceProvenance = [final.lib.sourceTypes.fromSource];
      };
    };
  };
}
