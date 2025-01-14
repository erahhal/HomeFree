{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/grocy";

  preStart = ''
    mkdir -p /var/lib/grocy
  '';

  version = "4.3.0";

  port = 3018;
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.grocy.enable == true then {
    grocy = {
      image = "lscr.io/linuxserver/grocy:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:80"
      ];

      volumes = [
        "${containerDataPath}:/config"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-grocy = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "grocy-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.grocy.enable == true then [
    {
      label = "grocy";
      name = "Grocy";
      project-name = "Grocy";
      systemd-service-name = "grocy";
      reverse-proxy = {
        enable = true;
        subdomains = [ "grocy" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.grocy.public;
      };
      backup = {
        paths = [
          "/var/lib/grocy"
        ];
      };
    }
  ] else [];
}

