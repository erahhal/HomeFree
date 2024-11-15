{ config, inputs, pkgs, lib, ... }:
let
  cfg = config.homefree.dynamic-dns;
in
{
  #-----------------------------------------------------------------------------------------------------
  # Dynamic DNS
  #-----------------------------------------------------------------------------------------------------

  services.ddclient-multi = {
    enable = true;
    interval = cfg.interval;
    usev4 = cfg.usev4;
    usev6 = cfg.usev6;
    verbose = true;
    zones = lib.map (zone: {
      protocol = zone.protocol;
      username = zone.username;
      zone = zone.zone;
      domains = zone.domains;
      passwordFile = zone.passwordFile;
    }) cfg.zones;
  };

  ## @TODO: Move to host config
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
