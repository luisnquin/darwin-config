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
    avdConfig = pkgs.writeShellApplication {
      name = "avd-config";
      runtimeInputs = with pkgs; [coreutils gawk];
      text = ''
        for home in ${lib.escapeShellArgs config.local.android.avd.homes}; do
          for ini in "$home"/*.avd/config.ini; do
            [ -f "$ini" ] || continue

            awk -v pairs=${lib.escapeShellArg (lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${v}") config.local.android.avd.config))} '
              BEGIN {
                n = split(pairs, lines, "\n")
                for (i = 1; i <= n; i++) {
                  eq = index(lines[i], "=")
                  want[substr(lines[i], 1, eq - 1)] = substr(lines[i], eq + 1)
                }
              }
              {
                eq = index($0, "=")
                key = substr($0, 1, eq - 1)
                if (eq && key in want) {
                  print key "=" want[key]
                  seen[key] = 1
                  next
                }
                print
              }
              END { for (key in want) if (!(key in seen)) print key "=" want[key] }
            ' "$ini" > "$ini.new"

            if cmp -s "$ini" "$ini.new"; then
              rm "$ini.new"
            else
              mv "$ini.new" "$ini"
              echo "avd-config: updated $ini"
            fi
          done
        done
      '';
    };
  in {
    options.local.android.avd = {
      homes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        # ~/.zsh/.zlogin repoints ANDROID_AVD_HOME there while /ext stalls on Gatekeeper
        default = [
          "${config.local.ext.cache}/android/avd"
          "${config.home.homeDirectory}/android-staged/avd"
        ];
        description = "Directories whose AVDs get `config` written into their config.ini.";
      };

      config = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "hw.gpu.enabled" = "yes";
          "hw.gpu.mode" = "host";
        };
        description = ''
          config.ini keys enforced on every AVD at activation. `hw.gpu.mode=auto`
          lets the emulator pick lavapipe, and fall back to software GL under
          memory pressure, which holds its buffers in host RAM.
        '';
      };
    };

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

      activation.avdConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${lib.getExe avdConfig}
      '';

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
