{inputs, ...}: {
  flake.modules.darwin.users = {
    users.users.luisnquin = {
      openssh.authorizedKeys.keys = inputs.identity.lib.ssh.authorizedKeys.rose;
    };
  };
}
