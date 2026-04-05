{
  programs.openclaw = {
    enable = false;
    config = {
      # TODO: set OPENCLAW_GATEWAY_TOKEN env var or try with agenix
      gateway.mode = "local";

      # channels.telegram = {
      #   tokenFile = "/run/agenix/telegram-bot-token"; # any file path works
      #   allowFrom = [12345678]; # your Telegram user ID
      # };
    };

    bundledPlugins = {
      summarize.enable = true; # Summarize web pages, PDFs, videos
      peekaboo.enable = true; # Take screenshots
      poltergeist.enable = false; # Control your macOS UI
      sag.enable = false; # Text-to-speech
      camsnap.enable = false; # Camera snapshots
      gogcli.enable = false; # Google Calendar
      bird.enable = false; # Twitter/X
      sonoscli.enable = false; # Sonos control
    };

    instances.default = {
      enable = true;
      stateDir = "~/.openclaw";
      workspaceDir = "~/.openclaw/workspace";
      launchd.enable = true;
    };
  };
}
