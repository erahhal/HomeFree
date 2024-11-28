{ config, pkgs, hostParams, userParams, ... }:
{
  virtualisation.oci-containers.containers = if config.homefree.services.headscale-ui.enable == true then {
    headscale-ui = {
      image = "ghcr.io/gurucomputing/headscale-ui:latest";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "10.0.0.1:3009:8080"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  homefree.proxied-hosts = if config.homefree.services.headscale-ui.enable == true then [
    {
      label = "headscale-ui";
      subdomains = [ "headscale-ui" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 3009;
      public = config.homefree.services.headscale-ui.public;
    }
  ] else [];
}

