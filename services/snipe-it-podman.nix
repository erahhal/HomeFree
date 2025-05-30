{ config, pkgs, ... }:
let
  containerDataPath = "/var/lib/snipeit";

  preStart = ''
    mkdir -p ${containerDataPath}

    MYSQL_PASSWORD=$(cat ${config.homefree.services.snipe-it.secrets.mysql-password})

    ## @TODO: reduce privileges here. snipeit shouldn't be admin
    ${pkgs.mariadb}/bin/mysql -e "CREATE USER IF NOT EXISTS 'snipeit'@'localhost'"
    ${pkgs.mariadb}/bin/mysql -e "ALTER USER 'snipeit'@'localhost IDENTIFIED BY '$MYSQL_PASSWORD'";
    ${pkgs.mariadb}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'snipeit'@'localhost'"
    ${pkgs.mariadb}/bin/mysql -e "CREATE USER 'snipeit'@'%'"
    ${pkgs.mariadb}/bin/mysql -e "ALTER USER 'snipeit'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'"
    ${pkgs.mariadb}/bin/mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'snipeit'@'%'"
  '';

  version = "v7.1.15";

  port = 3017;
in
{

  services.mysql = {
    ensureDatabases = [
      "snipeit"
    ];

    ensureUsers = [
      {
        name = "snipeit";
        ensurePermissions = {
          "snipeit.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  virtualisation.oci-containers.containers = if config.homefree.services.snipe-it.enable == true then {
    snipe-it = {
      image = "snipe/snipe-it:${version}";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:80"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}:/var/lib/snipeit"
      ];

      ## @TODO: this shouldn't need to be exposed to user config
      environmentFiles = [
        config.homefree.services.snipe-it.secrets.env
      ];

      environment = {
        TZ = config.homefree.system.timeZone;

        # --------------------------------------------
        # REQUIRED: DOCKER SPECIFIC SETTINGS
        # --------------------------------------------
        APP_VERSION = version;
        APP_PORT = toString port;

        # --------------------------------------------
        # REQUIRED: BASIC APP SETTINGS
        # --------------------------------------------
        APP_ENV = "production";
        APP_DEBUG = "false";
        ## Please regenerate the APP_KEY value by calling `docker compose run --rm snipeit php artisan key:generate --show`. Copy paste the value here
        # APP_KEY = "base64:lorempipsum";
        APP_URL = "https://snipeit.${config.homefree.system.domain}";
        # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones - TZ identifier
        APP_TIMEZONE = config.homefree.system.timeZone;
        ## Doesn't handle the module.nix local, with has the ".UTF-8" extension
        ## split off the first part before the dot
        APP_LOCALE = builtins.head (builtins.split "." config.homefree.system.defaultLocale);
        MAX_RESULTS = "500";

        # --------------------------------------------
        # REQUIRED: UPLOADED FILE STORAGE SETTINGS
        # --------------------------------------------
        PRIVATE_FILESYSTEM_DISK = "local";
        PUBLIC_FILESYSTEM_DISK = "local_public";

        # --------------------------------------------
        # REQUIRED: DATABASE SETTINGS
        # --------------------------------------------
        DB_CONNECTION = "mysql";
        DB_HOST = "10.0.0.1";
        DB_DATABASE = "snipeit";
        DB_PORT = "3306";
        DB_USERNAME = "snipeit";
        DB_PREFIX = "null";
        DB_DUMP_PATH = "'/usr/bin'";
        DB_CHARSET = "utf8mb4";
        DB_COLLATION = "utf8mb4_unicode_ci";

        # --------------------------------------------
        # OPTIONAL: SSL DATABASE SETTINGS
        # --------------------------------------------
        DB_SSL = "false";
        DB_SSL_IS_PAAS = "false";
        DB_SSL_KEY_PATH = "null";
        DB_SSL_CERT_PATH = "null";
        DB_SSL_CA_PATH = "null";
        DB_SSL_CIPHER = "null";
        DB_SSL_VERIFY_SERVER = "null";

        # --------------------------------------------
        # REQUIRED: OUTGOING MAIL SERVER SETTINGS
        # --------------------------------------------
        MAIL_MAILER = "smtp";
        MAIL_HOST = "mailhog";
        MAIL_PORT = "1025";
        MAIL_USERNAME = "null";
        MAIL_PASSWORD = "null";
        MAIL_TLS_VERIFY_PEER = "true";
        MAIL_FROM_ADDR = "you@example.com";
        MAIL_FROM_NAME = "'Snipe-IT'";
        MAIL_REPLYTO_ADDR = "you@example.com";
        MAIL_REPLYTO_NAME = "'Snipe-IT'";
        MAIL_AUTO_EMBED_METHOD = "'attachment'";

        # --------------------------------------------
        # REQUIRED: DATA PROTECTION
        # --------------------------------------------
        ALLOW_BACKUP_DELETE = "false";
        ALLOW_DATA_PURGE = "false";

        # --------------------------------------------
        # REQUIRED: IMAGE LIBRARY
        # This should be gd or imagick
        # --------------------------------------------
        IMAGE_LIB = "gd";

        # --------------------------------------------
        # OPTIONAL: BACKUP SETTINGS
        # --------------------------------------------
        MAIL_BACKUP_NOTIFICATION_DRIVER = "null";
        MAIL_BACKUP_NOTIFICATION_ADDRESS = "null";
        BACKUP_ENV = "true";

        # --------------------------------------------
        # OPTIONAL: SESSION SETTINGS
        # --------------------------------------------
        SESSION_LIFETIME = "12000";
        EXPIRE_ON_CLOSE = "false";
        ENCRYPT = "false";
        COOKIE_NAME = "snipeit_session";
        COOKIE_DOMAIN = "null";
        SECURE_COOKIES = "false";
        API_TOKEN_EXPIRATION_YEARS = "40";

        # --------------------------------------------
        # OPTIONAL: SECURITY HEADER SETTINGS
        # --------------------------------------------
        APP_TRUSTED_PROXIES = "192.168.1.1,10.0.0.1,172.16.0.0/12";
        ALLOW_IFRAMING = "false";
        REFERRER_POLICY = "same-origin";
        ENABLE_CSP = "false";
        CORS_ALLOWED_ORIGINS = "null";
        ENABLE_HSTS = "false";

        # --------------------------------------------
        # OPTIONAL: CACHE SETTINGS
        # --------------------------------------------
        CACHE_DRIVER = "file";
        SESSION_DRIVER = "file";
        QUEUE_DRIVER = "sync";
        CACHE_PREFIX = "snipeit";

        # --------------------------------------------
        # OPTIONAL: REDIS SETTINGS
        # --------------------------------------------
        REDIS_HOST = "null";
        REDIS_PASSWORD = "null";
        REDIS_PORT = "6379";

        # --------------------------------------------
        # OPTIONAL: MEMCACHED SETTINGS
        # --------------------------------------------
        MEMCACHED_HOST = "null";
        MEMCACHED_PORT = "null";

        # --------------------------------------------
        # OPTIONAL: PUBLIC S3 Settings
        # --------------------------------------------
        PUBLIC_AWS_SECRET_ACCESS_KEY = "null";
        PUBLIC_AWS_ACCESS_KEY_ID = "null";
        PUBLIC_AWS_DEFAULT_REGION = "null";
        PUBLIC_AWS_BUCKET = "null";
        PUBLIC_AWS_URL = "null";
        PUBLIC_AWS_BUCKET_ROOT = "null";

        # --------------------------------------------
        # OPTIONAL: PRIVATE S3 Settings
        # --------------------------------------------
        PRIVATE_AWS_ACCESS_KEY_ID = "null";
        PRIVATE_AWS_SECRET_ACCESS_KEY = "null";
        PRIVATE_AWS_DEFAULT_REGION = "null";
        PRIVATE_AWS_BUCKET = "null";
        PRIVATE_AWS_URL = "null";
        PRIVATE_AWS_BUCKET_ROOT = "null";

        # --------------------------------------------
        # OPTIONAL: AWS Settings
        # --------------------------------------------
        AWS_ACCESS_KEY_ID = "null";
        AWS_SECRET_ACCESS_KEY = "null";
        AWS_DEFAULT_REGION = "null";

        # --------------------------------------------
        # OPTIONAL: LOGIN THROTTLING
        # --------------------------------------------
        LOGIN_MAX_ATTEMPTS = "5";
        LOGIN_LOCKOUT_DURATION = "60";
        RESET_PASSWORD_LINK_EXPIRES = "900";

        # --------------------------------------------
        # OPTIONAL: MISC
        # --------------------------------------------
        LOG_CHANNEL = "stderr";
        LOG_MAX_DAYS = "10";
        APP_LOCKED = "false";
        APP_CIPHER = "AES-256-CBC";
        APP_FORCE_TLS = "false";
        GOOGLE_MAPS_API = "";
        LDAP_MEM_LIM = "500M";
        LDAP_TIME_LIM = "600";
      };
    };
  } else {};

  systemd.services.podman-snipe-it = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "snipe-it-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.snipe-it.enable == true then [
    {
      label = "snipe-it";
      name = "Snipe-IT";
      project-name = "Snipe-IT";
      systemd-service-names = [
        "podman-snipe-it"
        "mysql"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "snipeit" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.snipe-it.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
        mysql-databases = [
          "snipeit"
        ];
      };
    }
  ] else [];
}

