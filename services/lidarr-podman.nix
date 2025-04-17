{ config, pkgs, ... }:
let
  version = "2.10.3";
  port = 8976;
  containerDataPath = "/var/lib/lidarr";
  mediaPath = config.homefree.services.lidarr.media-path or "${containerDataPath}/media";
  downloadsPath = config.homefree.services.lidarr.downloads-path or "${containerDataPath}/downloads";
  preStart = ''
    mkdir -p ${containerDataPath}/config
    mkdir -p ${mediaPath}
    mkdir -p ${downloadsPath}
  '';
in
{
  systemd.services.podman-lidarr = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "lidarr-prestart" preStart}" ];
    };
  };

  virtualisation.oci-containers.containers = if config.homefree.services.lidarr.enable == true then {
    lidarr = {
      image = "lscr.io/linuxserver/lidarr:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:8686"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}:/config"
        "${mediaPath}:/music"
        "${downloadsPath}:/downloads"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        PUID = "1000";
        PGID = "100";
      };
    };
  } else {};

  homefree.service-config = if config.homefree.services.lidarr.enable == true then [
    {
      label = "lidarr";
      name = "Lidarr Music Collection Manager";
      project-name = "Lidarr";
      systemd-service-names = [
        "podman-lidarr"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "lidarr" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.lidarr.public;
      };
      backup = if config.homefree.services.lidarr.enable-backup-media then {
        paths = [
          mediaPath
        ];
      } else {};
    }
  ] else [];
}

