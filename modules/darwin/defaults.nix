{
  flake.modules.darwin.defaults = {config, ...}: {
    system.defaults = {
      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;

        AppleInterfaceStyle = "Light";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
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
        NSDisableAutomaticTermination = true;
      };

      LaunchServices = {
        # Whether to enable quarantine for downloaded applications
        LSQuarantine = false;
      };

      finder = {
        NewWindowTarget = "Computer";
        FXRemoveOldTrashItems = true;
        FXEnableExtensionChangeWarning = false;
      };

      screencapture = {
        target = "clipboard";
        show-thumbnail = false;
        disable-shadow = true;
        type = "jpg";
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 60 * 20;
      };

      CustomUserPreferences = {
        NSGlobalDomain = {
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSDocumentSaveNewDocumentsToCloud = false;
        };
        finder = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          WarnOnEmptyTrash = false;
          _FXShowPosixPathInTitle = true;
          _FXSortFoldersFirst = true;
        };

        "com.apple.desktopservices" = {
          DSDontWriteUSBStores = true;
          DSDontWriteNetworkStores = true;
        };
        "com.apple.systempreferences" = {
          NSQuitAlwaysKeepsWindows = false;
        };
        "com.apple.screencapture" = {
          "disable-shadow" = true;
        };
        "com.apple.finder" = {
          DisableAllAnimations = true;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
      };

      ".GlobalPreferences" = {
        # "com.apple.mouse.scaling" = 2;
        "com.apple.sound.beep.sound" = null;
      };
    };

    system.activationScripts.postActivation.text = ''
      # Activation runs as root on current nix-darwin, so explicitly target the user session.
      user_uid="$(id -u ${config.system.primaryUser})"

      # Disable Siri services
      sudo -u ${config.system.primaryUser} launchctl disable "user/$user_uid/com.apple.assistantd" 2>/dev/null || true
      sudo -u ${config.system.primaryUser} launchctl disable "gui/$user_uid/com.apple.assistantd" 2>/dev/null || true
      launchctl disable "system/com.apple.assistantd" 2>/dev/null || true

      sudo -u ${config.system.primaryUser} launchctl disable "user/$user_uid/com.apple.Siri.agent" 2>/dev/null || true
      sudo -u ${config.system.primaryUser} launchctl disable "gui/$user_uid/com.apple.Siri.agent" 2>/dev/null || true
      launchctl disable "system/com.apple.Siri.agent" 2>/dev/null || true
    '';
  };
}
