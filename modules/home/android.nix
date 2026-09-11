{
  flake.modules.homeManager.android = {
    config,
    lib,
    pkgs,
    ...
  }: let
    jdk = pkgs.jdk17;

    sdk = config.local.android.sdk;

    platform = "36";
    buildTools = "36.0.0";
    systemImage = "system-images;android-${platform};google_apis;arm64-v8a";

    avdName = "pixel_7-api${platform}";
    avdDevice = "pixel_7";

    components = [
      "build-tools;${buildTools}"
      "cmdline-tools;latest"
      "emulator"
      "platform-tools"
      "platforms;android-${platform}"
      systemImage
    ];

    androidSdkProvision = pkgs.writeShellApplication {
      name = "android-sdk-provision";
      runtimeInputs = with pkgs; [coreutils gnugrep];
      text = ''
        export ANDROID_HOME="${sdk}"
        export ANDROID_SDK_ROOT="$ANDROID_HOME"
        export JAVA_HOME="${jdk.home}"

        if ! command -v sdkmanager >/dev/null; then
          echo "sdkmanager not found; the android-commandlinetools cask bootstraps it" >&2
          exit 1
        fi

        set +o pipefail
        yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null
        set -o pipefail

        sdkmanager --sdk_root="$ANDROID_HOME" ${lib.escapeShellArgs components}

        # avdmanager derives the sdk root from where it sits and ignores
        # ANDROID_HOME, so the cask's copy reports an empty repository and
        # refuses the system image. The one just installed is inside the sdk.
        avdmanager="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"

        if ! "$avdmanager" list avd | grep -Fq "Name: ${avdName}"; then
          device=()
          if "$avdmanager" list device | grep -Fq '"${avdDevice}"'; then
            device=(--device "${avdDevice}")
          fi

          printf 'no\n' | "$avdmanager" create avd \
            --name "${avdName}" \
            --package "${systemImage}" \
            "''${device[@]}"
        fi
      '';
    };
  in {
    options.local.android.sdk = lib.mkOption {
      type = lib.types.str;
      default = "${config.local.ext.cache}/android/sdk";
      description = ''
        Root the Android SDK is provisioned into. Read by the darwin minisim
        module too, which shells out to <sdk>/emulator/emulator.
      '';
    };

    config.programs = {
      java = {
        enable = true;
        package = jdk;
      };

      gradle.enable = true;
    };

    config.home = {
      packages = [androidSdkProvision];

      # cmdline-tools first so the SDK copy shadows the bootstrap cask
      sessionPath = [
        "${sdk}/cmdline-tools/latest/bin"
        "${sdk}/emulator"
        "${sdk}/platform-tools"
      ];

      sessionVariables = {
        ANDROID_HOME = sdk;
        ANDROID_SDK_ROOT = sdk;
      };
    };
  };
}
