{ config, inputs, pkgs, ... }:
let
  ## @TODO: Update to support multiple zones
  ddclientConfig = builtins.elemAt config.homefree.dynamic-dns 0;
in
{
  #-----------------------------------------------------------------------------------------------------
  # Dynamic DNS
  #-----------------------------------------------------------------------------------------------------

  services.ddclient = {
    enable = true;
    interval = ddclientConfig.interval;
    protocol = ddclientConfig.protocol;
    username = ddclientConfig.username;
    zone = ddclientConfig.zone;
    domains = ddclientConfig.domains;
    passwordFile = "/run/secrets/ddclient/ddclient-password";
    usev4 = ddclientConfig.usev4;
    usev6 = ddclientConfig.usev6;
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
