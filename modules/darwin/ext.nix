{inputs, ...}: {
  flake.modules.darwin.ext = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (inputs.self.lib) ext;

    # SIP refuses every write to /etc/fstab, as root and through vifs alike, so
    # the mount cannot be declared there. diskutil takes the volume UUID, which
    # is what fstab would have been keyed by anyway: /Volumes names collide.
    mount = pkgs.writeShellScript "ext-mount" ''
      if ! /sbin/mount | /usr/bin/grep -q " on ${ext.path} ("; then
        # An attached volume auto-mounts at /Volumes/<name>, and from there
        # -mountPoint exits 0 without moving anything, so take the mount back
        # first and confirm afterwards where it actually landed.
        /usr/sbin/diskutil unmount ${ext.uuid} > /dev/null 2>&1
        /usr/sbin/diskutil mount -mountPoint ${ext.path} ${ext.uuid} || exit 1

        /sbin/mount | /usr/bin/grep -q " on ${ext.path} (" || exit 1
      fi

      # Ownership is recorded per volume on the boot disk, so it does not
      # survive a wipe. Without it the volume mounts noowners and every
      # attribute-preserving copy onto it fails with EPERM.
      /usr/sbin/diskutil enableOwnership ${ext.path} > /dev/null

      # Enabling ownership exposes the real root owner, root:wheel, which would
      # stop home-manager from creating its directories.
      /usr/sbin/chown ${config.system.primaryUser}:staff ${ext.path}
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

        # The daemon covers boot; this covers the rest of this activation,
        # whose home-manager step asserts the volume is mounted.
        ${mount}
      '';

      # SuccessfulExit=false retries until the disk shows up, but it stops
      # for good once a mount succeeds, so StartOnMount covers the replug:
      # the volume lands on /Volumes/ext and the script moves it to /ext.
      launchd.daemons.ext-mount.serviceConfig = {
        ProgramArguments = ["${mount}"];
        RunAtLoad = true;
        StartOnMount = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
      };
    };
  };
}
