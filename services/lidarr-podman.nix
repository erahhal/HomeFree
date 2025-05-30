{ config, pkgs, ... }:
let
  version = "2.10.3";
  port = 8976;
  containerDataPath = "/var/lib/lidarr";
  configPath = "${containerDataPath}/config";
  mediaPath = config.homefree.services.lidarr.media-path or "${containerDataPath}/media";
  downloadsPath = config.homefree.services.lidarr.downloads-path or "${containerDataPath}/downloads";
  preStart = ''
    mkdir -p ${configPath}
    mkdir -p ${mediaPath}
    mkdir -p ${downloadsPath}
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.lidarr.enable == true then {
    lidarr = {
      image = "lscr.io/linuxserver/lidarr:${version}";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:8686"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${configPath}:/config"
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

  systemd.services.podman-lidarr = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "lidarr-prestart" preStart}" ];
    };
  };

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
          downloadsPath
        ];
      } else {};
    }
  ] else [];
}

