{
  flake.modules.darwin.iphone = {pkgs, ...}: let
    pymobiledevice3 = pkgs.python3Packages.pymobiledevice3;
  in {
    environment.systemPackages = [pymobiledevice3];

    # iOS 17+ exposes developer services (screenshot included) only over a
    # RemoteXPC tunnel. Creating the tunnel needs root for the utun interface,
    # while the unprivileged client just talks to it on 127.0.0.1:49151.
    # Running tunneld as an always-on root daemon lets a plain ssh session
    # capture screenshots without sudo.
    launchd.daemons.pymobiledevice-tunneld = {
      serviceConfig = {
        ProgramArguments = ["${pymobiledevice3}/bin/pymobiledevice3" "remote" "tunneld"];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/pymobiledevice-tunneld.log";
        StandardErrorPath = "/var/log/pymobiledevice-tunneld.log";
      };
    };
  };
}
