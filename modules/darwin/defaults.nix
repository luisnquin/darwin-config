{
  flake.modules.darwin.defaults = {config, ...}: {
    system.defaults = {
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;

        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = true;
        AppleTemperatureUnit = "Celsius";
        AppleICUForce24HourTime = true;
        ApplePressAndHoldEnabled = false;
        AppleKeyboardUIMode = 2;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        AppleShowScrollBars = "Always";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.1;
      };

      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = 2;
        "com.apple.sound.beep.sound" = null;
      };
    };
  };
}
