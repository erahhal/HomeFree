{ config, inputs, pkgs, ... }:

{
  #-----------------------------------------------------------------------------------------------------
  # Dynamic DNS
  #-----------------------------------------------------------------------------------------------------

  services.ddclient = {
    enable = true;
    interval = "10m";
    protocol = "hetzner";
    username = "erahhal";
    zone = "homefree.host";
    domains = [ "*" "www" "dev" ];
    passwordFile = "/run/secrets/ddclient/ddclient-password";
    use = "web, web=ipinfo.io/ip";
    verbose = true;
  };

  sops.secrets = {
    "ddclient/ddclient-password" = {
      format = "yaml";
      sopsFile = ../secrets/ddclient.yaml;

      owner = "homefree";
      path = "/run/secrets/ddclient/ddclient-password";
      restartUnits = [ "ddclient.service" ];
    };
  };
}
