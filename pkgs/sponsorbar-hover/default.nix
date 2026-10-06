{
  lib,
  swift,
  swiftPackages,
}:
swiftPackages.stdenv.mkDerivation {
  pname = "sponsorbar-hover";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./src;
  };

  nativeBuildInputs = [swift];

  buildPhase = ''
    runHook preBuild
    swiftc -O src/main.swift -o sponsorbar-hover
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 sponsorbar-hover "$out/bin/sponsorbar-hover"
    runHook postInstall
  '';

  meta = {
    description = "Idle SponsorBar menu bar hover helper";
    mainProgram = "sponsorbar-hover";
    platforms = lib.platforms.darwin;
  };
}
