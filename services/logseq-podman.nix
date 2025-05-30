{ config, ... }:
let
  version = "3.3.13";
  port = 8938;
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.logseq.enable == true then {
    logseq = {
      image = "ghcr.io/logseq/logseq-webapp:latest";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:80"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-logseq = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
  };

  homefree.service-config = if config.homefree.services.logseq.enable == true then [
    {
      label = "logseq";
      name = "Logseq Knowledge Management";
      project-name = "Logseq";
      systemd-service-names = [
        "podman-logseq"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "logseq" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.logseq.public;
      };
      backup = {
      };
    }
  ] else [];
}

