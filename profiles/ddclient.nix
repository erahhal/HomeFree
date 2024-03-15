{ config, inputs, pkgs, ... }:

{
  #-----------------------------------------------------------------------------------------------------
  # Dynamic DNS
  #-----------------------------------------------------------------------------------------------------

  # @TODO: https://discourse.nixos.org/t/ddclient-options/20935
  services.ddclient = {
    enable = true;
    interval = "10m";
    # protocol = "zoneedit1";
    # username = "erahhal";
    # zone = "homefree.host";
    # passwordFile = config.age.secrets.ddclient.path;
    # verbose = true;
    configFile = config.age.secrets.ddclient-conf.path;
  };
}
