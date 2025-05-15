{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/vaultwarden-podman";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';

  port = 8222;
  version = "1.33.2";
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.vaultwarden.enable == true then {
    vaultwarden = {
      image = "vaultwarden/server:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:80"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}:/data"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-vaultwarden = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "vaultwarden-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.vaultwarden.enable == true then [
    {
      label = "vaultwarden";
      name = "Password Manager";
      project-name = "Vaultwarden";
      systemd-service-names = [
        "podman-vaultwarden"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "vaultwarden" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.vaultwarden.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}
