{
  flake.modules.darwin.menuBar = {
    system.defaults = {
      controlcenter = {
        AirDrop = false;
        Bluetooth = false;
        Display = false;
        FocusModes = true;
        NowPlaying = false;
        Sound = false;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDayOfWeek = true;
        ShowDate = 0;
        ShowSeconds = false;
      };

      CustomUserPreferences."com.apple.TextInputMenu" = {
        visible = true;
      };
    };
  };
}
