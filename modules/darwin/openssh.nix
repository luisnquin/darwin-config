{
  flake.modules.darwin.openssh = {config, ...}: {
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        AuthenticationMethods publickey
        PubkeyAuthentication yes
        PermitRootLogin no
        MaxAuthTries 3
        AllowUsers ${config.system.primaryUser}
        ClientAliveCountMax 3
        ClientAliveInterval 60
      '';
    };
  };
}
