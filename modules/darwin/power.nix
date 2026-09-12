{
  flake.modules.darwin.power = {config, ...}: {
    power = {
      restartAfterFreeze = true;
      restartAfterPowerFailure = true;

      # tailscaled answers nothing while the machine sleeps, and a magic packet
      # only reaches it from the same LAN, so remote access needs it awake.
      sleep.computer = "never";
    };

    # Needs /etc/kcpassword from `sysadminctl -autologin set` to take effect.
    system.defaults.loginwindow.autoLoginUser = config.system.primaryUser;

    # Wake for network access has no nix-darwin option, and a reinstall does not
    # carry the setting over.
    system.activationScripts.extraActivation.text = ''
      /usr/sbin/systemsetup -setWakeOnNetworkAccess on &> /dev/null

      if /usr/bin/fdesetup status | /usr/bin/grep -q 'FileVault is On'; then
        printf >&2 'warning: FileVault is on; an unplanned restart stops at the unlock screen, unreachable over ssh. Run `sudo fdesetup disable`, then `sudo sysadminctl -autologin set -userName %s -password -`.\n' ${config.system.primaryUser}
      elif ! /usr/bin/defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser > /dev/null 2>&1 || [ ! -f /etc/kcpassword ]; then
        printf >&2 'warning: auto-login is not set up; the menu bar agents will not start after a restart. Run `sudo sysadminctl -autologin set -userName %s -password -`.\n' ${config.system.primaryUser}
      fi
    '';
  };
}
