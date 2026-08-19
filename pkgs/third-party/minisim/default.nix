{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "minisim";
  version = "0.10.0";

  src = fetchurl {
    url = "https://github.com/okwasniewski/MiniSim/releases/download/v${finalAttrs.version}/MiniSim.app.zip";
    hash = "sha256-tq9XdfCvsbPBKkOPw1wfQgeoc0H7054lbm0/v6Wspk0=";
  };

  nativeBuildInputs = [unzip];

  # The archive holds MiniSim.app beside an __MACOSX sidecar tree, so there is
  # no single directory for the unpacker to descend into.
  sourceRoot = ".";

  # The bundle arrives Developer ID signed and notarized. fixupPhase would
  # rewrite Mach-O headers and re-sign ad-hoc, which breaks the seal and drops
  # the Accessibility grant the app needs to read simulator windows.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R MiniSim.app $out/Applications/

    runHook postInstall
  '';

  meta = {
    description = "Menu bar utility to launch iOS simulators and Android emulators";
    homepage = "https://github.com/okwasniewski/MiniSim";
    license = lib.licenses.mit;
    platforms = ["aarch64-darwin" "x86_64-darwin"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
