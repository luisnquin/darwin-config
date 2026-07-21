{
  flake.modules.homeManager.android = {
    config,
    lib,
    pkgs,
    ...
  }: let
    jdk = pkgs.jdk17;

    sdk = "${config.home.homeDirectory}/Library/Android/sdk";

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

        if ! avdmanager list avd | grep -Fq "Name: ${avdName}"; then
          device=()
          if avdmanager list device | grep -Fq '"${avdDevice}"'; then
            device=(--device "${avdDevice}")
          fi

          printf 'no\n' | avdmanager create avd \
            --name "${avdName}" \
            --package "${systemImage}" \
            "''${device[@]}"
        fi
      '';
    };
  in {
    programs = {
      java = {
        enable = true;
        package = jdk;
      };

      gradle.enable = true;
    };

    home = {
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
