{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/baikal";

  port = 3007;

  preStart = ''
    mkdir -p ${containerDataPath}/config
    mkdir -p ${containerDataPath}/Specific
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.baikal.enable == true then {
    baikal = {
      image = "ckulka/baikal:nginx";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:80"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/config:/var/www/baikal/config"
        "${containerDataPath}/Specific:/var/www/baikal/Specific"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-baikal = {
    after = [ "dns-ready.service" ];
    requires =[ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "baikal-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.baikal.enable == true then [
    {
      label = "baikal";
      name = "Baikal CalDAV/CardDAV";
      project-name = "Baikal";
      systemd-service-names = [
        "podman-baikal"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "baikal" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
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

