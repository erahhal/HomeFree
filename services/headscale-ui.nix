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
  #       http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
  #       https-domains = [ config.homefree.system.domain ];
  #       host = "10.0.0.1";
  #       port = 3009;
  #       public = config.homefree.services.headscale-ui.public;
  #     };
  #   }
  # ] else [];

  ## Reference of what caddy config might look like:
  # let
  #   headscale-ui-config = lib.elemAt (lib.filter (service-config: service-config.label == "headscale-ui") config.homefree.service-config) 0;
  # in
  # {
  #   ## Needed so as to host ui and headscale enpoint on separate domains
  #   "https://headscale.${config.homefree.system.domain}" = {
  #     logFormat = ''
  #       output file ${config.services.caddy.logDir}/access-headscale.log
  #     '';
  #     extraConfig = ''
  #       @headscale-options {
  #         host headscale.${config.homefree.system.domain}
  #         method OPTIONS
  #       }
  #       @headscale-other {
  #         host headscale.${config.homefree.system.domain}
  #       }
  #       handle @headscale-options {
  #         header {
  #           Access-Control-Allow-Origin https://headscale-ui.${config.homefree.system.domain}
  #           Access-Control-Allow-Headers *
  #           Access-Control-Allow-Methods "POST, GET, OPTIONS, DELETE"
  #         }
  #         respond 204
  #       }
  #       handle @headscale-other {
  #         reverse_proxy http://10.0.0.1:8087 {
  #           header_down Access-Control-Allow-Origin https://headscale-ui.${config.homefree.system.domain}
  #           header_down Access-Control-Allow-Methods "POST, GET, OPTIONS, DELETE"
  #           header_down Access-Control-Allow-Headers *
  #         }
  #     ''
  #     + (if headscale-ui-config.public == false then ''
  #         bind 10.0.0.1
  #     '' else ''
  #         bind 10.0.0.1 ${config.homefree.system.domain}
  #     '')
  #     + ''
  #       }
  #     '';
  #   };
  # }
}

