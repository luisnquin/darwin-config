{
  apple-sdk_26,
  darwin,
  fetchFromGitHub,
  lib,
  libicns,
  swift,
  swiftpm,
  swiftpm2nix,
  swiftPackages,
}: let
  generated = swiftpm2nix.helpers ./nix;
in
  swiftPackages.stdenv.mkDerivation (finalAttrs: {
    pname = "opendevicehub";
    version = "0.2.0";

    src = fetchFromGitHub {
      owner = "Mastersam07";
      repo = "OpenDeviceHub";
      rev = "e50f07f1f4480cb14d57f192df7bf598ca26e708";
      hash = "sha256-eSyaxiBRIBWgesgslAV2kPegOm59DCwA4OqZ2akmVho=";
    };

    patches = [
      ./patches/no-sparkle.patch
      ./patches/no-cli-installer.patch
      ./patches/accessibility.patch
      ./patches/wait-for-device-set.patch
    ];
    sourceRoot = "${finalAttrs.src.name}/engine";
    patchFlags = ["-p1" "-d" ".."];
    postUnpack = ''chmod -R u+w "$sourceRoot/.."'';

    nativeBuildInputs = [
      darwin.autoSignDarwinBinariesHook
      libicns
      swift
      swiftpm
    ];

    configurePhase =
      # Same SwiftUIMacros problem as minisim: swift propagates SDK 27.
      ''
        export DEVELOPER_DIR=${apple-sdk_26} SDKROOT=${apple-sdk_26.sdkroot}
      ''
      + generated.configure;

    swiftpmFlags = [
      "-Xlinker"
      "-platform_version"
      "-Xlinker"
      "macos"
      "-Xlinker"
      "14.0"
      "-Xlinker"
      (lib.versions.majorMinor apple-sdk_26.version)
    ];

    buildPhase = ''
      runHook preBuild
      for product in odhub-viewer odhub; do
        swift build -c release --product "$product" $swiftpmFlags
      done
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      app="$out/Applications/OpenDeviceHub.app"
      bin="$(swiftpmBinPath)"
      mkdir -p "$app/Contents/"{MacOS,Resources} "$out/bin"

      cp "$bin/odhub-viewer" "$app/Contents/MacOS/OpenDeviceHub"
      cp "$bin/odhub" "$app/Contents/MacOS/odhub"
      ln -s "$app/Contents/MacOS/odhub" "$out/bin/odhub"

      sed -e 's/__MARKETING_VERSION__/${finalAttrs.version}/' -e 's/__BUILD_NUMBER__/1/' \
        ../packaging/Info.plist > "$app/Contents/Info.plist"
      printf 'APPL????' > "$app/Contents/PkgInfo"

      png2icns "$app/Contents/Resources/AppIcon.icns" \
        ../icons/icon-{16,32,128,256,512,1024}.png

      runHook postInstall
    '';

    meta = {
      description = "One window per iOS simulator, for Xcode 26 and 27";
      homepage = "https://github.com/Mastersam07/OpenDeviceHub";
      license = lib.licenses.mit;
      mainProgram = "odhub";
      platforms = ["aarch64-darwin"];
    };
  })
