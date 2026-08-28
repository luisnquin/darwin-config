{
  fetchFromGitHub,
  git,
  jq,
  lib,
  librsvg,
  stdenvNoCC,
  unzip,
  # Xcode is not in nixpkgs and cannot be, so the toolchain is taken from the
  # host install. Overridable for a beta or a second Xcode side by side.
  xcodeDir ? "/Applications/Xcode.app/Contents/Developer",
}: let
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "okwasniewski";
    repo = "MiniSim";
    tag = "v${version}";
    hash = "sha256-WaIg+ND1wF87N50a4Cgy1Cj/r79HtMCvbiKKLIvBt6A=";
  };

  # SwiftPM resolves its caches through NSHomeDirectory(), which reads the passwd
  # entry (/var/empty for the build users) and ignores $HOME. Only
  # CFFIXED_USER_HOME moves it somewhere writable.
  xcodeEnv = ''
    export DEVELOPER_DIR=${lib.escapeShellArg xcodeDir}
    export HOME="$NIX_BUILD_TOP/home"
    export CFFIXED_USER_HOME="$HOME"
    mkdir -p "$HOME"
  '';

  swiftpmDir = "$NIX_BUILD_TOP/swiftpm";

  # workspace-state.json records where each checkout and artifact lives as an
  # absolute path, so it is stored with the build directory replaced by a
  # placeholder and rewritten by whoever consumes the output.
  swiftpmDirPlaceholder = "@swiftpmDir@";

  # Everything the build downloads, pulled once behind a fixed output hash so
  # the build itself never touches the network.
  swiftpmDeps = stdenvNoCC.mkDerivation {
    pname = "minisim-swiftpm-deps";
    inherit version src;

    nativeBuildInputs = [git jq unzip];
    dontFixup = true;

    # Skips the minimal darwin sandbox profile, which SwiftPM cannot compile a
    # remote Package.swift under. Needs the patched lix from
    # `flake.overlays.lix`; stock lix ignores this on darwin.
    __noChroot = true;

    buildPhase = ''
      runHook preBuild

      ${xcodeEnv}

      "$DEVELOPER_DIR/usr/bin/xcodebuild" \
        -project MiniSim.xcodeproj \
        -scheme MiniSim \
        -clonedSourcePackagesDirPath "${swiftpmDir}" \
        -packageCachePath "$NIX_BUILD_TOP/swiftpm-cache" \
        -onlyUsePackageVersionsFromResolvedFile \
        -resolvePackageDependencies

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R "${swiftpmDir}"/. $out/
      # git leaves parts of the checkouts read-only and the rewriting below has
      # to touch them.
      chmod -R u+w $out

      jq -r '.object.dependencies[]
             | "\(.subpath)\t\(.packageRef.location)\t\(.state.checkoutState.revision)"' \
        $out/workspace-state.json |
        while IFS="$(printf '\t')" read -r subpath location revision; do
          checkout=$out/checkouts/$subpath
          # The checkout still names the mirror it was cloned from, but by its
          # path in the build directory rather than the copy under $out.
          mirror=$out/repositories/$(basename "$(git -C "$checkout" config remote.origin.url)")

          # Under repositories/ sits a full mirror of every dependency, a
          # gigabyte of history for SwiftLint alone, and SwiftPM insists one be
          # there or it re-clones from the network. It never reads past the
          # pinned revision though, so each mirror is rebuilt locally as a
          # depth-1 repo holding just that commit. The remote url, the mirror
          # refspec and the branch HEAD points at all have to survive: SwiftPM
          # compares them before it agrees to reuse the mirror.
          original=$mirror.original
          mv "$mirror" "$original"
          git -C "$original" config uploadpack.allowAnySHA1InWant true
          headRef=$(git -C "$original" symbolic-ref HEAD)

          git init --bare --quiet "$mirror"
          git -C "$mirror" remote add origin "$location"
          git -C "$mirror" config remote.origin.mirror true
          git -C "$mirror" config remote.origin.tagOpt --no-tags
          git -C "$mirror" config --replace-all remote.origin.fetch '+refs/*:refs/*'
          # A packfile is ordered after the packs it was built from, and the
          # mirror this one is fetched from was packed by github, which repacks
          # between fetches: two resolutions of the same revision would hold the
          # same objects in a differently ordered pack. So the mirror is kept
          # entirely loose -- a set of files named after their own contents has
          # no order left to record. unpackLimit past any dependency's object
          # count covers the fetch, gc.auto stops git packing it straight back
          # up, and the loop below catches whatever still slipped through.
          git -C "$mirror" \
            -c fetch.unpackLimit=1000000 \
            -c gc.auto=0 \
            -c maintenance.auto=false \
            fetch --quiet --depth 1 "file://$original" "$revision"

          # unpack-objects skips objects it can already reach, so every pack has
          # to be out of the way before any of them is unpacked.
          mkdir "$NIX_BUILD_TOP/packs"
          for pack in "$mirror"/objects/pack/*.pack; do
            mv "$pack" "$NIX_BUILD_TOP/packs/"
          done
          rm -rf "$mirror/objects/pack" "$mirror/objects/info/packs"
          mkdir -p "$mirror/objects/pack"
          for pack in "$NIX_BUILD_TOP/packs"/*.pack; do
            git -C "$mirror" unpack-objects -q < "$pack"
          done
          rm -rf "$NIX_BUILD_TOP/packs"
          git -C "$mirror" update-ref "$headRef" "$revision"
          git -C "$mirror" symbolic-ref HEAD "$headRef"

          # A version-pinned dependency is looked up by its tag, so the ones
          # naming this revision come along.
          git -C "$original" for-each-ref \
            --format='%(refname) %(objectname) %(*objectname)' refs/tags |
            while read -r ref object peeled; do
              if [ "''${peeled:-$object}" = "$revision" ]; then
                git -C "$mirror" update-ref "$ref" "$revision"
              fi
            done

          rm -rf "$original" "$mirror/logs" "$mirror/FETCH_HEAD"

          # The checkout's index caches each file's inode and mtime and its
          # reflog is timestamped, so both differ between two identical
          # resolutions. read-tree rebuilds the index with those fields zeroed.
          rm -rf "$checkout/.git/logs" "$checkout/.git/index"
          git -C "$checkout" read-tree HEAD

          # git's sample hooks are shebanged into the store, which a
          # fixed-output derivation is not allowed to reference.
          rm -rf "$mirror/hooks" "$checkout/.git/hooks"
        done

      # Where the checkouts and mirrors live is recorded as an absolute path in
      # three places, all of them naming this build directory. Only these three
      # are text; rewriting by grep would walk into the object files.
      for file in \
        $out/workspace-state.json \
        $out/checkouts/*/.git/config \
        $out/checkouts/*/.git/objects/info/alternates; do
        substituteInPlace "$file" \
          --replace-fail "${swiftpmDir}" ${lib.escapeShellArg swiftpmDirPlaceholder}
      done

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-SP+Of9Gzcrp8ChDGFWraqC98+6RAU41v7CIgEViBrtQ=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "minisim";
    inherit version src;

    # SwiftPM shells out to unzip for the Sparkle and SwiftLint artifact bundles
    # and reports "could not find executable for 'unzip'" without it on PATH.
    nativeBuildInputs = [librsvg unzip];

    # The stock menu bar glyph is a filled slab; this outline replaces it. The
    # asset is a template image, so only the alpha channel matters.
    postPatch = ''
      rsvg-convert -w 22 -h 38 ${./menubar-iphone.svg} \
        -o MiniSim/Assets.xcassets/iphone.imageset/iphone@2x.png
    '';

    # xcodebuild signs the bundle itself, and darwin's fixupPhase would then
    # rewrite the Mach-O headers behind its back and break the seal.
    dontFixup = true;

    # See swiftpmDeps: the manifests are compiled here too, once, to load the
    # already-resolved graph.
    __noChroot = true;

    buildPhase = ''
      runHook preBuild

      ${xcodeEnv}

      cp -R ${swiftpmDeps} "${swiftpmDir}"
      chmod -R u+w "${swiftpmDir}"
      for file in \
        "${swiftpmDir}"/workspace-state.json \
        "${swiftpmDir}"/checkouts/*/.git/config \
        "${swiftpmDir}"/checkouts/*/.git/objects/info/alternates; do
        substituteInPlace "$file" \
          --replace-fail ${lib.escapeShellArg swiftpmDirPlaceholder} "${swiftpmDir}"
      done

      "$DEVELOPER_DIR/usr/bin/xcodebuild" \
        -project MiniSim.xcodeproj \
        -scheme MiniSim \
        -configuration Release \
        -derivedDataPath "$NIX_BUILD_TOP/derived-data" \
        -clonedSourcePackagesDirPath "${swiftpmDir}" \
        -packageCachePath "$NIX_BUILD_TOP/swiftpm-cache" \
        -disableAutomaticPackageResolution \
        -onlyUsePackageVersionsFromResolvedFile \
        -skipMacroValidation \
        OTHER_SWIFT_FLAGS="\$(inherited) -disable-sandbox" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -R "$NIX_BUILD_TOP/derived-data/Build/Products/Release/MiniSim.app" $out/Applications/

      # arm64 refuses to load an unsigned Mach-O, and the build ran with signing
      # off, so the bundle needs at least an ad-hoc identity to launch at all.
      /usr/bin/codesign --force --deep --sign - $out/Applications/MiniSim.app

      runHook postInstall
    '';

    passthru = {inherit swiftpmDeps;};

    meta = {
      description = "Menu bar utility to launch iOS simulators and Android emulators";
      homepage = "https://github.com/okwasniewski/MiniSim";
      license = lib.licenses.mit;
      platforms = ["aarch64-darwin" "x86_64-darwin"];
    };
  }
