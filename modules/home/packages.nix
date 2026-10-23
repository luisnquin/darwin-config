{inputs, ...}: {
  flake.modules.homeManager.packages = {
    config,
    pkgs,
    ...
  }: let
    phone = inputs.nixos-config-pkgs.packages.${pkgs.stdenv.hostPlatform.system}.phone;
  in {
    home.packages = with pkgs; [
      alejandra
      nixgrep
      phone
      # the accessibility bridge the phone CLI on another machine drives over ssh
      phone.receiver
      senv
    ];

    launchd.agents.phone = {
      enable = true;
      domain = "user";
      config = {
        EnvironmentVariables = {
          inherit (config.home.sessionVariables) ANDROID_HOME ANDROID_SDK_ROOT ANDROID_AVD_HOME;
          SHELL = "/bin/sh";
        };
        ProgramArguments = [
          "${phone}/bin/phone"
          "daemon"
          "--keep"
          "pixel_7-api36"
          "--keep"
          "pixel_7-api36-b"
          "--keep"
          "pixel_7-api36-c"
          "--adopt"
          "qa-1"
          "--adopt"
          "qa-2"
          "--adopt"
          "qa-3"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 30;
        StandardOutPath = "/tmp/phone-daemon.log";
        StandardErrorPath = "/tmp/phone-daemon.log";
      };
    };
  };
}
