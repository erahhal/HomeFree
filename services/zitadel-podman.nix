{ config, pkgs, ... }:

## Default username: zitadel-admin@zitadel.${config.homefree.system.domain}
## Default password: Password1!

let
  version = "v2.67.5";
  containerDataPath = "/var/lib/zitadel";
  port = 3241;

  preStart = ''
    mkdir -p ${containerDataPath}
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.zitadel.enable == true then {
    zitadel = {
      image = "ghcr.io/zitadel/zitadel:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:8080"
      ];

      volumes = [
        "${containerDataPath}:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];

      cmd = [
        "start-from-init"
        "--masterkeyFromEnv"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;

        ZITADEL_DATABASE_POSTGRES_HOST = "10.0.0.1";
        ZITADEL_DATABASE_POSTGRES_PORT = "5432";
        ZITADEL_DATABASE_POSTGRES_DATABASE = "zitadel";
        ZITADEL_DATABASE_POSTGRES_USER_USERNAME = "zitadel";
        ZITADEL_DATABASE_POSTGRES_USER_PASSWORD = "zitadel";
        ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE = "disable";
        ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME = "postgres";
        ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD = "postgres";
        ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE = "disable";
        ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME = "zitadel-admin@zitadel.${config.homefree.system.domain}";
        ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD = "Password1!";

        ZITADEL_EXTERNALDOMAIN = "sso.${config.homefree.system.domain}";
        ZITADEL_EXTERNALPORT = "443";
        ZITADEL_EXTERNALSECURE = "true";
        ZITADEL_TLS_ENABLED = "false";
      };

      environmentFiles = [
        config.homefree.services.zitadel.secrets.env
      ];
    };
  } else {};

  systemd.services.podman-zitadel = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "zitadel-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.zitadel.enable == true then [
    {
      label = "zitadel";
      name = "Auth";
      project-name = "Zitadel";
      systemd-service-names = [
        "podman-zitadel"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "sso" "auth" "zitadel" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.zitadel.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}

