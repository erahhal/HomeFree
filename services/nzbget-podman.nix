{ config, pkgs, ... }:
let
  version = "version-v24.8";
  port = 6799;
  containerDataPath = "/var/lib/nzbget";
  configPath = "${containerDataPath}/config";
  downloadsPath = config.homefree.services.nzbget.downloads-path or "${containerDataPath}/downloads";
  preStart = ''
    mkdir -p ${configPath}
    mkdir -p ${downloadsPath}
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.nzbget.enable == true then {
    nzbget = {
      image = "lscr.io/linuxserver/nzbget:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:6789"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${configPath}:/config"
        "${downloadsPath}:/downloads"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        PUID = "1000";
        PGID = "100";
        # NZBGET_USER = "nzbget"; #optional
        # NZBGET_PASS = "tegbzn6789"; #optional
      };
    };
  } else {};

  systemd.services.podman-nzbget = {
    after = [ "dns-ready.target" ];
    wants = [ "dns-ready.target" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "nzbget-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.nzbget.enable == true then [
    {
      label = "nzbet";
      name = "NZB Downloader";
      project-name = "NZBGet";
      systemd-service-names = [
        "podman-nzbget"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "nzbget" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.nzbget.public;
      };
      backup = if config.homefree.services.nzbget.enable-backup-media then {
        paths = [
          downloadsPath
        ];
      } else {};
    }
  ] else [];
}
