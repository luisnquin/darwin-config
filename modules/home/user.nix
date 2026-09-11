{
  flake.modules.homeManager.user = {pkgs, ...}: {
    home = {
      stateVersion = "26.11";
      username = "luisnquin";
      homeDirectory = pkgs.lib.mkForce "/Users/luisnquin";
    };
  };
}
