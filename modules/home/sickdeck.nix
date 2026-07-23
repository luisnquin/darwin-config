{
  flake.modules.homeManager.sickdeck = {config, ...}: {
    services.sickdeck = {
      enable = true;
      allowedLogins = ["luisnquin@github"];

      # A launchd agent inherits none of the shell environment, and the Android
      # layer shells out to adb/emulator/avdmanager resolved from ANDROID_HOME.
      environment = {
        inherit (config.home.sessionVariables) ANDROID_HOME ANDROID_SDK_ROOT;
        JAVA_HOME = "${config.programs.java.package.home}";
      };
    };
  };
}
