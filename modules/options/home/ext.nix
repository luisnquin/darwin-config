{inputs, ...}: {
  flake.modules.homeManager.extOptions = {
    config,
    lib,
    ...
  }: let
    cfg = config.local.ext;

    pathOption = default: description:
      lib.mkOption {
        inherit default description;
        type = lib.types.str;
      };
  in {
    options.local.ext = {
      path = pathOption inputs.self.lib.ext.path ''
        Mount point of the external SSD that holds toolchains and caches.
        Created via /etc/synthetic.conf and mounted by UUID by the darwin
        ext module; SIP makes /etc/fstab unwritable even as root.
      '';

      cache = pathOption inputs.self.lib.ext.cache ''
        Root for state its owning tool rebuilds on demand. Safe to delete at
        any point, at the cost of the time it takes to refetch. Anything kept
        beside it on the volume is durable by construction.
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
