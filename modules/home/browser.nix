{
  flake.modules.homeManager.browser = {
    programs.zen-browser = {
      enable = true;

      profiles.default = rec {
        pins = {
          "GitHub" = {
            id = "48e8a119-5a14-4826-9545-91c8e8dd3bf6";
            workspace = spaces."Rendezvous".id;
            url = "https://github.com";
            position = 101;
            isEssential = false;
          };
          "WhatsApp Web" = {
            id = "1eabb6a3-911b-4fa9-9eaf-232a3703db19";
            workspace = spaces."Rendezvous".id;
            url = "https://web.whatsapp.com/";
            position = 102;
            isEssential = false;
          };
          "Telegram Web" = {
            id = "5065293b-1c04-40ee-ba1d-99a231873864";
            url = "https://web.telegram.org/k/";
            position = 103;
            isEssential = true;
          };
        };

        spaces = {
          "Rendezvous" = {
            id = "572910e1-4468-4832-a869-0b3a93e2f165";
            icon = "chrome://browser/skin/zen-icons/selectable/navigate.svg";
            position = 1000;
            theme = {
              type = "gradient";
              colors = [
                {
                  red = 123;
                  green = 56;
                  blue = 58;
                  algorithm = "analogous";
                  type = "explicit-lightness";
                  lightness = 35;
                  position.x = 301;
                  position.y = 176;
                  primary = true;
                  custom = false;
                }
                {
                  red = 123;
                  green = 110;
                  blue = 55;
                  algorithm = "analogous";
                  type = "explicit-lightness";
                  lightness = 35;
                  position.x = 260;
                  position.y = 271;
                  primary = false;
                  custom = false;
                }
                {
                  red = 122;
                  green = 56;
                  blue = 114;
                  algorithm = "analogous";
                  type = "explicit-lightness";
                  lightness = 35;
                  position.x = 255;
                  position.y = 84;
                  primary = false;
                  custom = false;
                }
              ];
              opacity = 0.8;
              texture = 0.5;
            };
          };
        };
      };
    };
  };
}
