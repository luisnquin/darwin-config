{inputs, ...}: {
  flake.modules.homeManager.extOptions = {
    config,
    lib,
    ...
  }: let
    cfg = config.local.ext;
  in {
    options.local.ext.path = lib.mkOption {
      type = lib.types.str;
      default = inputs.self.lib.ext.path;
      description = ''
        Mount point of the external SSD that holds toolchains and caches.
        Created via /etc/synthetic.conf and mounted by UUID by the darwin
        ext module; SIP makes /etc/fstab unwritable even as root.
      '';
    };

    # Before checkLinkTargets so a missing volume fails the switch instead of
    # leaving dangling symlinks.
    config.home.activation.extMount = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      # A synthetic.conf mount point exists whether or not the volume is on it,
      # so -d proves nothing; ask the mount table instead.
      if ! /sbin/mount | /usr/bin/grep -q " on ${cfg.path} ("; then
        errorEcho "${cfg.path} is not mounted; is the volume attached?"
        exit 1
      fi
    '';
  };
}
