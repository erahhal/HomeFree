{ config, inputs, pkgs, ... }:

{
  #-----------------------------------------------------------------------------------------------------
  # Dynamic DNS
  #-----------------------------------------------------------------------------------------------------

  services.ddclient = {
    enable = true;
    interval = config.homefree.ddclient.interval;
    protocol = config.homefree.ddclient.protocol;
    username = config.homefree.ddclient.username;
    zone = config.homefree.ddclient.zone;
    domains = config.homefree.ddclient.domains;
    passwordFile = "/run/secrets/ddclient/ddclient-password";
    usev4 = config.homefree.ddclient.usev4;
    usev6 = config.homefree.ddclient.usev6;
    verbose = true;
  };

  sops.secrets = {
    "ddclient/ddclient-password" = {
      format = "yaml";
      sopsFile = ../secrets/ddclient.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/ddclient/ddclient-password";
      restartUnits = [ "ddclient.service" ];
    };
  };
}
