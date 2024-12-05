{ config, ... }:
{
  virtualisation.oci-containers.containers = if config.homefree.services.headscale-ui.enable == true then {
    headscale-ui = {
      image = "ghcr.io/gurucomputing/headscale-ui:latest";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:3009:8080"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  # homefree.service-config = if config.homefree.services.headscale-ui.enable == true then [
  #   {
  #     label = "headscale-ui";
  #     reverse-proxy = {
  #       enable = true;
  #       subdomains = [ "headscale-ui" ];
  #       http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
  #       https-domains = [ config.homefree.system.domain ];
  #       port = 3009;
  #       public = config.homefree.services.headscale-ui.public;
  #     };
  #   }
  # ] else [];
}

