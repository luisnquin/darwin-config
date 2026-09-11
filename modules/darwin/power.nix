{
  flake.modules.darwin.power = {
    power = {
      restartAfterFreeze = true;
      restartAfterPowerFailure = true;

      # tailscaled answers nothing while the machine sleeps, and a magic packet
      # only reaches it from the same LAN, so remote access needs it awake.
      sleep.computer = "never";
    };

    # Wake for network access has no nix-darwin option, and a reinstall does not
    # carry the setting over.
    system.activationScripts.extraActivation.text = ''
      /usr/sbin/systemsetup -setWakeOnNetworkAccess on &> /dev/null
    '';
  };
}
