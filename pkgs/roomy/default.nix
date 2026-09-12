{
  darwin,
  darwinMinVersionHook,
  lib,
  swift,
  swiftPackages,
}:
swiftPackages.stdenv.mkDerivation {
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

  nativeBuildInputs = [
    darwin.autoSignDarwinBinariesHook
    swift
  ];

  buildInputs = [(darwinMinVersionHook "13.0")];

  buildPhase = ''
    runHook preBuild

    swiftc -O Sources/Logic.swift Sources/main.swift -o Roomy

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

    runHook postInstall
  '';

  meta = {
    description = "Menu bar indicator for free disk space with cleanup tips";
    license = lib.licenses.mit;
    platforms = ["aarch64-darwin"];
  };
}
