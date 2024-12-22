{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/baikal";

  preStart = ''
    mkdir -p /var/lib/baikal/config
    mkdir -p /var/lib/baikal/Specific
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.baikal.enable == true then {
    baikal = {
      image = "ckulka/baikal:nginx";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:3007:80"
      ];

      volumes = [
        "${containerDataPath}/config:/var/www/baikal/config"
        "${containerDataPath}/Specific:/var/www/baikal/Specific"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-baikal = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "baikal-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.baikal.enable == true then [
    {
      label = "baikal";
      reverse-proxy = {
        enable = true;
        subdomains = [ "baikal" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 3007;
        public = config.homefree.services.baikal.public;
      };
      backup = {
        paths = [
          "${containerDataPath}/config"
          "${containerDataPath}/Specific"
        ];
      };
    }
  ] else [];
}

