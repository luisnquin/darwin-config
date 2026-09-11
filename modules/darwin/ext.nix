{inputs, ...}: {
  flake.modules.darwin.ext = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (inputs.self.lib) ext;

    hm = config.home-manager.users.${config.system.primaryUser};

    # Everything the home modules redirect onto the volume, matched by value
    # so a cache added there needs no second list kept in step here.
    guiVariables =
      lib.filterAttrs (_: value: lib.isString value && lib.hasPrefix "${ext.path}/" value)
      hm.home.sessionVariables;

    # launchctl setenv is session state, not a file, so it dies with the login
    # session and no switch runs at boot to put it back. An agent carries it
    # across both: user agents are bootstrapped into the Aqua session itself,
    # which makes a plain setenv land in the one domain GUI apps read.
    guiEnv = pkgs.writeShellScript "ext-gui-env" (lib.concatLines (lib.mapAttrsToList
      (name: value: "/bin/launchctl setenv ${name} ${lib.escapeShellArg value}")
      guiVariables));

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
      # stop home-manager from creating its directories. Only ever when it is
      # wrong: TCC withholds an external volume from a daemon, so the chown is
      # denied even as root, and being the last command it would leave the job
      # exiting 1 for KeepAlive to read as a failed mount and respawn.
      owner=${config.system.primaryUser}:staff

      if [ "$(/usr/bin/stat -f %Su:%Sg ${ext.path})" != "$owner" ]; then
        /usr/sbin/chown "$owner" ${ext.path}
      fi
    '';
  in {
    options.local.ext.guiEnvScript = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      default = guiEnv;
      description = ''
        Puts every variable pointing into the volume in the Aqua session.
        Run it before launching a GUI app from an agent, which would otherwise
        race the agent that does it at login.
      '';
    };

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

      # Agents start in an unspecified order, so an app needing these cannot
      # rely on this one having run; minisim re-runs the script before opening.
      launchd.user.agents.ext-env.serviceConfig = {
        ProgramArguments = ["${guiEnv}"];
        RunAtLoad = true;
      };

      # SuccessfulExit=false retries until the disk shows up, but it stops
      # for good once a mount succeeds, so StartOnMount covers the replug:
      # the volume lands on /Volumes/ext and the script moves it to /ext.
      launchd.daemons.ext-mount.serviceConfig = {
        # The store is a volume of its own, unlocked at boot by a sibling
        # daemon that launchd sequences this one against in no way. A store
        # path as the program is a missing executable whenever that race is
        # lost, and launchd answers those with a penalty box rather than with
        # the retry KeepAlive gives a run that failed.
        ProgramArguments = ["/bin/sh" "-c" "/bin/wait4path ${mount} && exec ${mount}"];
        RunAtLoad = true;
        StartOnMount = true;
        KeepAlive.SuccessfulExit = false;
        ThrottleInterval = 10;
      };
    };
  };
}
