{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/grocy";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';

  version = "4.3.0";

  port = 3018;
in
{
  ## @NOTE: Default username and password: admin, admin
  ## @TODO: Setup LDAP login (see /var/lib/grocy/data/config.php)
  ##        Can this be set up with env vars?
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
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "grocy-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.grocy.enable == true then [
    {
      label = "grocy";
      name = "Grocy";
      project-name = "Grocy";
      systemd-service-names = [
        "podman-grocy"
      ];
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
          containerDataPath
        ];
      };
    }
  ] else [];
}

