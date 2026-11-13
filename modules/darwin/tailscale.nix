{
  flake.modules.darwin.tailscale = {config, ...}: {
    services.tailscale.enable = true;

    # tailscaled lacks TCC Removable Volumes access; its sessions hang opening /ext.
    system.activationScripts.postActivation.text = ''
      ${config.services.tailscale.package}/bin/tailscale set --ssh=false || true
    '';
  };
}
