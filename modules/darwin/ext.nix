{inputs, ...}: {
  flake.modules.darwin.ext = {
    lib,
    pkgs,
    ...
  }: let
    inherit (inputs.self.lib) ext;

    # SIP refuses every write to /etc/fstab, as root and through vifs alike, so
    # the mount cannot be declared there. diskutil takes the volume UUID, which
    # is what fstab would have been keyed by anyway: /Volumes names collide.
    mount = pkgs.writeShellScript "ext-mount" ''
      if /sbin/mount | /usr/bin/grep -q " on ${ext.path} ("; then
        exit 0
      fi

      exec /usr/sbin/diskutil mount -mountPoint ${ext.path} ${ext.uuid}
    '';
  in {
    config = lib.mkIf (ext.uuid != null) {
      system.activationScripts.extraActivation.text = ''
        printf >&2 'setting up %s...\n' ${ext.path}

        candidate=$(/usr/bin/mktemp)
        /usr/bin/grep -v ${lib.escapeShellArg "^${ext.volume}$"} /etc/synthetic.conf > "$candidate" || true
        printf '%s\n' ${lib.escapeShellArg ext.volume} >> "$candidate"

        if ! /usr/bin/cmp -s "$candidate" /etc/synthetic.conf; then
          /usr/bin/install -m 0644 -o root -g wheel "$candidate" /etc/synthetic.conf
        fi

        /bin/rm -f "$candidate"

        # Stitches the mount point now rather than at the next boot.
        if [ ! -d ${ext.path} ]; then
          /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
        fi

        # The daemon covers boot and hotplug; this covers the rest of this
        # activation, whose home-manager step asserts the volume is mounted.
        ${mount}
      '';

      # SuccessfulExit=false retries until the disk shows up, so a volume
      # attached after boot is picked up without a switch.
      launchd.daemons.ext-mount.serviceConfig = {
        ProgramArguments = ["${mount}"];
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
      };
    };
  };
}
