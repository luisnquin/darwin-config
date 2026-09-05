{
  flake.modules.darwin.users = {
    users.users.luisnquin = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXW6vsDRgI/AiOdGnQOTyiz1uLFL0o66u0Ahcw9VWyd luis@quinones.pro"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICOvNB4XZFchiWUCpdXaNcyoyUi9+7SnGCvrRk2CM129"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOy0naPj/yYMQtfKt/geDwWyS16IujRV3UbC4P2xQalE"
      ];
    };
  };
}
