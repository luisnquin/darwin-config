{
  flake.modules.darwin.userActivation = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.local.userActivation;
    in {
      options.local.userActivation = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands run as system.primaryUser during activation, replacing the removed system.activationScripts.postUserActivation.";
      };

      config = mkIf (cfg != "") {
        system.activationScripts.postActivation.text = ''
          su ${config.system.primaryUser} -s /bin/sh <<'POST_USER_ACTIVATION'
          ${cfg}
          POST_USER_ACTIVATION
        '';
      };
    };
}
