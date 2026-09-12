{inputs, ...}: {
  flake.modules.homeManager.knownHosts = {
    config,
    lib,
    pkgs,
    ...
  }: let
    pinned = pkgs.writeText "known_hosts" (lib.concatLines inputs.identity.lib.ssh.knownHostsLines);

    target = "${config.home.homeDirectory}/.ssh/known_hosts";
  in {
    # Seeded into ssh's own file rather than declared as one: ssh keeps
    # appending hosts it learns, and the pins are only ever added, never removed.
    home.activation.knownHosts = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [[ -v DRY_RUN ]]; then
        echo "would seed pinned hosts into ${target}"
      else
        /bin/mkdir -p -m 700 ${config.home.homeDirectory}/.ssh
        touch ${target}
        while IFS= read -r line; do
          grep -qxF "$line" ${target} || printf '%s\n' "$line" >> ${target}
        done < ${pinned}
      fi
    '';
  };
}
