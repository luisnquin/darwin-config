{
  flake.modules.darwin.signedApps = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.local.signedApps;
      dir = "/var/db/local-codesign";

      sign = name: app: let
        stage = "${dir}/${name}.app";
        label = config.launchd.user.agents.${app.agent}.serviceConfig.Label;
      in ''
        if [ "$(cat ${dir}/${name}.source 2>/dev/null)" != ${app.source} ]; then
          /usr/bin/csreq -b ${dir}/${name}.requirement \
            -r "=identifier \"$(/usr/bin/defaults read ${app.source}/Contents/Info CFBundleIdentifier)\" and certificate leaf = H\"$leaf\""
          # App Management blocks editing a registered app in place, even as root.
          rm -rf ${stage}
          cp -R ${app.source} ${stage}
          chmod -R u+w ${stage}
          ${pkgs.rcodesign}/bin/rcodesign sign \
            --pem-file ${dir}/key.pem --pem-file ${dir}/cert.pem \
            --code-requirements-path ${dir}/${name}.requirement ${stage}
          rm -rf /Applications/${name}.app
          mv ${stage} /Applications/${name}.app
          echo ${app.source} > ${dir}/${name}.source
          /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u ${config.system.primaryUser})/${label}" 2>/dev/null || true
        fi
      '';
    in {
      options.local.signedApps = mkOption {
        default = {};
        description = ''
          Apps copied to /Applications/<name>.app and signed with a certificate
          local to this machine. Ad-hoc signatures tie TCC grants to the cdhash,
          so every rebuild of a nix-built app re-prompts; a certificate keeps
          one identity. Its key stays root-only, outside the store.
        '';
        type = types.attrsOf (types.submodule {
          options = {
            source = mkOption {
              type = types.path;
              description = "The .app bundle to copy.";
            };
            agent = mkOption {
              type = types.str;
              description = "launchd.user.agents entry restarted when the copy changes.";
            };
          };
        });
      };

      config = mkIf (cfg != {}) {
        system.activationScripts.extraActivation.text = ''
          if [ ! -e ${dir}/key.pem ]; then
            /usr/bin/install -d -m 700 ${dir}
            /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 36500 \
              -keyout ${dir}/key.pem -out ${dir}/cert.pem \
              -config ${pkgs.writeText "local-codesign.cnf" ''
            [req]
            distinguished_name=dn
            x509_extensions=ext
            prompt=no
            [dn]
            CN=local code signing
            [ext]
            basicConstraints=critical,CA:false
            keyUsage=critical,digitalSignature
            extendedKeyUsage=critical,codeSigning
          ''}
          fi
          leaf=$(/usr/bin/openssl x509 -in ${dir}/cert.pem -noout -fingerprint -sha1 | /usr/bin/cut -d= -f2 | /usr/bin/tr -d :)
          ${concatStrings (mapAttrsToList sign cfg)}
        '';
      };
    };
}
