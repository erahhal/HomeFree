## Restore from backup:
## cp /var/lib/immich/backups/immich-db-backup-1738144800006.sql.gz ~/
## cd ~/
## gzip -d immich-db-backup-1738144800006.sql.gz
## psql -U postgres
## drop database immich;
## exit
## sudo systemctl restart postgres # adds immich database back
## psql -f immich-db-backup-1738144800006.sql -U postgres -d immich


## Migration from Nix service to podman. Docker container has hard coded path.

## double quotes are used for db identifiers, single quotes for strings
## If any special characters or upper case, must surround with double quotes

## update asset_files set path = replace(path, '/var/lib/immich', '/usr/src/app/upload');
## update assets set "originalPath" = replace("originalPath", '/var/lib/immich', '/usr/src/app/upload');
## update person set "thumbnailPath" = replace("thumbnailPath", '/var/lib/immich', '/usr/src/app/upload');
{ config, lib, pkgs, ... }:
let
  version = "v1.131.3";
  version-redis = "6.2-alpine";
  containerDataPath = "/var/lib/immich";
  # Seems to be hard coded in docker container, so can't override
  uploadLocation = "/usr/src/app/upload";

  port = 2283;
  port-machine-learning = 3003;
  port-redis = 6379;
  database-name = "immich";
  database-user = "immich";

  preStart = ''
    mkdir -p ${containerDataPath}/backups
    mkdir -p ${containerDataPath}/encoded-video
    mkdir -p ${containerDataPath}/library
    mkdir -p ${containerDataPath}/profile
    mkdir -p ${containerDataPath}/thumbs
    mkdir -p ${containerDataPath}/upload
    mkdir -p /var/cache/immich
  '';
in
{
  ## @TODO: Move to scripts run from containers
  environment.systemPackages = if config.homefree.services.immich.enable then [
    pkgs.immich-cli
    pkgs.immich-go
  ] else [];

  ## Copied from nixpkgs
  services.postgresql = if config.homefree.services.immich.enable then {
    enable = true;
    ensureDatabases = [ database-name ];
    ensureUsers = [
      {
        name = database-user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    extensions = ps: with ps; [ pgvecto-rs ];
    settings = {
      shared_preload_libraries = [ "vectors.so" ];
      search_path = "\"$user\", public, vectors";
    };
  } else {};

  ## Copied from nixpkgs
  systemd.services.postgresql.serviceConfig.ExecStartPost = if config.homefree.services.immich.enable then
  let
    sqlFile = pkgs.writeText "immich-pgvectors-setup.sql" ''
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS vectors;
      CREATE EXTENSION IF NOT EXISTS cube;
      CREATE EXTENSION IF NOT EXISTS earthdistance;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;

      ALTER SCHEMA public OWNER TO ${database-user};
      ALTER SCHEMA vectors OWNER TO ${database-user};
      GRANT SELECT ON TABLE pg_vector_index_stat TO ${database-user};

      ALTER EXTENSION vectors UPDATE;
    '';
  in
  [
    ''
      ${lib.getExe' config.services.postgresql.package "psql"} -d "${database-name}" -f "${sqlFile}"
    ''
  ] else [];

  virtualisation.oci-containers.containers = if config.homefree.services.immich.enable then {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:2283"
      ];

      volumes = [
        "${containerDataPath}:${uploadLocation}"
        "/etc/localtime:/etc/localtime:ro"
        "/run/postgresql:/run/postgresql"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;

        # IMMICH_LOG_LEVEL = "verbose";
        UPLOAD_LOCATION = "${uploadLocation}";
        THUMB_LOCATION = "${uploadLocation}/thumbs";
        ENCODED_VIDEO_LOCATION = "${uploadLocation}/encoded-video";
        PROFILE_LOCATION = "${uploadLocation}/profile";
        BACKUP_LOCATION = "${uploadLocation}/backups";
        DB_HOSTNAME = "/run/postgresql";
        DB_PORT = "5432";
        DB_DATABASE_NAME = database-name;
        DB_USERNAME = database-user;
        REDIS_HOSTNAME = "immich-redis";
        REDIS_PORT = toString port-redis;
        IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:${toString port-machine-learning}";
        PUBLIC_IMMICH_SERVER_URL = "https://photos.${config.homefree.system.domain}";
        IMMICH_HOST = "0.0.0.0";
        IMMICH_PORT = toString port;
      };
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
        ## 1GB of memory, reduces SSD/SD Card wear
        "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        "--device=/dev/bus/usb:/dev/bus/usb"  # Passes the USB Coral, needs to be modified for other versions
        "--device=/dev/dri/renderD128:/dev/dri/renderD128" # For intel hwaccel, needs to be updated for your hardware
        "--cap-add=CAP_PERFMON" # For GPU statistics
        "--privileged"
      ];

      volumes = [
        "${containerDataPath}:${uploadLocation}"
        "/var/cache/immich:/var/cache/immich"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;

        MACHINE_LEARNING_WORKERS = "2";
        MACHINE_LEARNING_WORKER_TIMEOUT = "120";
        MACHINE_LEARNING_CACHE_FOLDER = "/var/cache/immich";
        IMMICH_HOST = "0.0.0.0";
        IMMICH_PORT = toString port-machine-learning;
      };
    };

    immich-redis = {
      image = "redis:${version-redis}";

      autoStart  = true;

      extraOptions = [
        "--pull=always"
        "--health-cmd=redis-cli ping || exit 1"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-immich-server = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "imimich-server-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.immich.enable == true then [
    {
      label = "immich";
      name = "Photos";
      project-name = "Immich";
      release-tracking = {
        type = "github";
        project = "immich-app/immich";
      };
      systemd-service-names = [
        "podman-immich-server"
        "podman-immich-machine-learning"
        "podman-immich-redis"
        "postgresql"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "photos" "immich" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = config.services.immich.port;
        public = config.homefree.services.immich.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
        postgres-databases = [
          "immich"
        ];
      };
    }
  ] else [];
}
