{ config, pkgs, ... }:
let
  # image = "postgres";
  # version = "16.9";
  image = "tensorchord/vchord-postgres";
  version = "pg16-v0.4.2";
  port = 6432;
  containerDataPath = "/var/lib/postgres-vectorchord-podman";
  containerDataPathInternal = "/var/lib/postgresql/data";

  hba-file = pkgs.writeText "pg_hba.conf" ''
    #type database  DBuser  auth-method
    local all       all     trust

    #type database DBuser origin-address auth-method
    # ipv4
    host  all      all     127.0.0.1/32   trust
    # host
    host  all      all     10.0.0.0/16   trust
    # podman
    host  all      all     10.88.0.0/16   trust
    # ipv6
    host all       all     ::1/128        trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local   replication     all                                     trust
    host    replication     all             127.0.0.1/32            trust
    host    replication     all             10.0.0.0/16             trust
    host    replication     all             10.88.0.0/16            trust
    host    replication     all             ::1/128                 trust
  '';

  config-file = pkgs.writeText "postgres.conf" ''
    hba_file = '${containerDataPathInternal}/pgdata/pg_hba.conf'
    listen_addresses = '*'
    max_connections = 100
    port = ${toString port}
    shared_buffers = 128MB
    dynamic_shared_memory_type = posix
    max_wal_size = 1GB
    min_wal_size = 80MB
    datestyle = 'iso, mdy'
    timezone = '${config.homefree.system.timeZone}'
    lc_messages = 'en_US.utf8'              # locale for system error message
    lc_monetary = 'en_US.utf8'              # locale for monetary formatting
    lc_numeric = 'en_US.utf8'               # locale for number formatting
    lc_time = 'en_US.utf8'                  # locale for time formatting
    default_text_search_config = 'pg_catalog.english'
  '';

  preStart = ''
    mkdir -p ${containerDataPath}/pgdata
  '';
in
{
  virtualisation.oci-containers.containers = {
    postgres-vectorchord = {
      image = "${image}:${version}";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
        "--shm-size=128M"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString port}"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}:${containerDataPathInternal}"
        "${config-file}:${containerDataPathInternal}/pgdata/postgresql.conf"
        "${hba-file}:${containerDataPathInternal}/pgdata/pg_hba.conf"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        PGDATA = "/var/lib/postgresql/data/pgdata";
        POSTGRES_PASSWORD = "changeme";
      };
    };
  };

  systemd.services.podman-postgres-vectorchord = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "postgres-vectorchord-prestart" preStart}" ];
    };
  };

  homefree.service-config = [
    {
      label = "postgres-vectorchord";
      name = "VectorChord PostgreSQL";
      project-name = "VectorChord PostgreSQL";
      systemd-service-names = [
        "podman-postgres-vectorchord"
      ];
      reverse-proxy = {
        enable = false;
      };
      backup = {
        paths = [
        #  containerDataPath
        ];
      };
    }
  ];
}
