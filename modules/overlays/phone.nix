{inputs, ...}: {
  flake.overlays.phone = final: prev: let
    # `phone` depends on deckhand by path, so both crates have to sit beside
    # each other in one tree before cargo ever sees them.
    src = final.runCommandLocal "phone-source" {} ''
      mkdir -p $out/pkgs
      cp -R ${../../pkgs/phone} $out/pkgs/phone
      cp -R ${inputs.deckhand} $out/pkgs/deckhand
      chmod -R u+w $out
    '';
  in {
    phone = final.rustPlatform.buildRustPackage {
      pname = "phone";
      version = "0.1.0";

      inherit src;

      sourceRoot = "phone-source/pkgs/phone";
      cargoLock.lockFile = ../../pkgs/phone/Cargo.lock;

      # deckhand's build.rs compiles the ObjC bridge against CoreSimulator and
      # SimulatorKit, which the default SDK is too old to describe.
      buildInputs = [final.apple-sdk_26];

      meta = {
        description = "Read and press an iOS Simulator on the host that owns it";
        license = final.lib.licenses.asl20;
        mainProgram = "phone";
        platforms = ["aarch64-darwin"];
        sourceProvenance = [final.lib.sourceTypes.fromSource];
      };
    };
  };
}
