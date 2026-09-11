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
        # The store is a volume a sibling daemon unlocks at boot, and launchd
        # sequences this one against it in no way, so the first run exits 126
        # until KeepAlive happens to retry late enough.
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/wait4path ${pymobiledevice3} && exec ${pymobiledevice3}/bin/pymobiledevice3 remote tunneld"
        ];
        RunAtLoad = true;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        StartInterval = 30;
        ThrottleInterval = 10;
        StandardOutPath = "/var/log/pymobiledevice-tunneld.log";
        StandardErrorPath = "/var/log/pymobiledevice-tunneld.log";
      };
    };
  };
}
