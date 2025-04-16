{ config, ... }:
let
  version = "3.3.13";
  port = 8975;
  database-name = "joplin";
  database-user = "joplin";
in
{
  services.postgresql = if config.homefree.services.joplin.enable then {
    enable = true;
    ensureDatabases = [ database-name ];
    ensureUsers = [
      {
        name = database-user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  } else {};

  virtualisation.oci-containers.containers = if config.homefree.services.joplin.enable == true then {
    joplin = {
      image = "joplin/server:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:22300"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/run/postgresql:/run/postgresql"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        DB_CLIENT = "pg";
        POSTGRES_DATABASE = database-name;
        POSTGRES_USER = database-user;
        POSTGRES_PORT = "5432";
        POSTGRES_HOST = "/run/postgresql";
        APP_BASE_URL = "https://notes.${config.homefree.system.domain}";
      };
    };
  } else {};

  homefree.service-config = if config.homefree.services.joplin.enable == true then [
    {
      label = "notes";
      name = "Joplin Notes";
      project-name = "Joplin";
      systemd-service-names = [
        "podman-joplin"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "notes" "joplin" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.joplin.public;
      };
      backup = {
        postgres-databases = [
          database-name
        ];
      };
    }
  ] else [];
}

