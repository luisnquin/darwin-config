{
  lib,
  stdenvNoCC,
  # Xcode is not in nixpkgs and cannot be, so the toolchain is taken from the
  # host install. Overridable for a beta or a second Xcode side by side.
  xcodeDir ? "/Applications/Xcode.app/Contents/Developer",
}:
stdenvNoCC.mkDerivation {
  pname = "roomy";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Sources
      ./Tests
      ./Info.plist
    ];
  };

  # xcodebuild-less build, but the toolchain still lives under /Applications,
  # which the minimal darwin sandbox cannot see. Needs the patched lix from
  # `flake.overlays.lix`; stock lix ignores this on darwin.
  __noChroot = true;

  # codesign seals the binary; darwin's fixupPhase would rewrite the Mach-O
  # headers behind its back and break the seal.
  dontFixup = true;

  buildPhase = ''
    runHook preBuild

    export DEVELOPER_DIR=${lib.escapeShellArg xcodeDir}
    swiftc() {
      "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc" \
        -O \
        -target arm64-apple-macos13.0 \
        -sdk "$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" \
        -module-cache-path "$NIX_BUILD_TOP/module-cache" \
        "$@"
    }

    swiftc Sources/Logic.swift Sources/main.swift -o Roomy

    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck

    swiftc Sources/Logic.swift Tests/main.swift -o roomy-tests
    ./roomy-tests

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    app=$out/Applications/Roomy.app
    mkdir -p "$app/Contents/MacOS"
    cp Roomy "$app/Contents/MacOS/"
    cp Info.plist "$app/Contents/"

    # arm64 refuses to load an unsigned Mach-O, so the bundle needs at least an
    # ad-hoc identity to launch at all.
    /usr/bin/codesign --force --sign - "$app"

    runHook postInstall
  '';

  meta = {
    description = "Menu bar indicator for free disk space with cleanup tips";
    license = lib.licenses.mit;
    platforms = ["aarch64-darwin"];
  };
}
