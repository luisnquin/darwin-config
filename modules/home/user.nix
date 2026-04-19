{
  flake.modules.homeManager.user = {pkgs, ...}: {
    home = {
      stateVersion = "25.05";
      username = "luisnquin";
      homeDirectory = pkgs.lib.mkForce "/Users/luisnquin";
    };
  };
}
