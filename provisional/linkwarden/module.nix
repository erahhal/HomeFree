{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.linkwarden;
  isPostgresUnixSocket = lib.hasPrefix "/" cfg.database.host;

  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
in
{
  options.services.linkwarden = {
    enable = mkEnableOption "Linkwarden";
    package = lib.mkPackageOption pkgs "linkwarden" { };

    storageLocation = mkOption {
      type = types.path;
      default = "/var/lib/linkwarden";
      description = "Directory used to store media files. If it is not the default, the directory has to be created manually such that the linkwarden user is able to read and write to it.";
    };
    cacheLocation = mkOption {
      type = types.path;
      default = "/var/cache/linkwarden";
      description = "Directory used as cache. If it is not the default, the directory has to be created manually such that the linkwarden user is able to read and write to it.";
    };

    enableRegistration = mkEnableOption "registration for new users";

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        PAGINATION_TAKE_COUNT = "50";
      };
      description = ''
        Extra configuration environment variables. Refer to the [documentation](https://docs.linkwarden.app/self-hosting/environment-variables) for options.
      '';
    };

    secretsFile = mkOption {
      type = types.str // {
        # We don't want users to be able to pass a path literal here but
        # it should look like a path.
        check = it: lib.isString it && lib.types.path.check it;
      };
      example = "/run/secrets/linkwarden";
      description = ''
        Path of a file with extra environment variables to be loaded from disk.
        This file is not added to the nix store, so it can be used to pass secrets to linkwarden.
        Refer to the [documentation](https://docs.linkwarden.app/self-hosting/environment-variables) for options.

        Linkwarden needs at least a nextauth secret. To set a database password use POSTGRES_PASSWORD:
        ```
        NEXTAUTH_SECRET=<secret>
        POSTGRES_PASSWORD=<pass>
        ```
      '';
    };

    host = mkOption {
      type = types.str;
      default = "localhost";
      description = "The host that Linkwarden will listen on.";
    };
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "The port that Linkwarden will listen on.";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the Linkwarden port in the firewall";
    };
    user = mkOption {
      type = types.str;
      default = "linkwarden";
      description = "The user Linkwarden should run as.";
    };
    group = mkOption {
      type = types.str;
      default = "linkwarden";
      description = "The group Linkwarden should run as.";
    };

    database = {
      enable =
        mkEnableOption "the postgresql database for use with Linkwarden. See {option}`services.postgresql`"
        // {
          default = true;
        };
      createDB = mkEnableOption "the automatic creation of the database for Linkwarden." // {
        default = true;
      };
      name = mkOption {
        type = types.str;
        default = "linkwarden";
        description = "The name of the Linkwarden database.";
      };
      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        example = "127.0.0.1";
        description = "Hostname or address of the postgresql server. If an absolute path is given here, it will be interpreted as a unix socket path.";
      };
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Port of the postgresql server.";
      };
      user = mkOption {
        type = types.str;
        default = "linkwarden";
        description = "The database user for Linkwarden.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.database.createDB -> cfg.database.name == cfg.database.user;
        message = "The postgres module requires the database name and the database user name to be the same.";
      }
    ];

    services.postgresql = mkIf cfg.database.enable {
      enable = true;
      ensureDatabases = mkIf cfg.database.createDB [ cfg.database.name ];
      ensureUsers = mkIf cfg.database.createDB [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services.linkwarden.environment = {
      LINKWARDEN_HOST = cfg.host;
      LINKWARDEN_PORT = toString cfg.port;
      LINKWARDEN_CACHE_DIR = cfg.cacheLocation;
      STORAGE_FOLDER = cfg.storageLocation;
      NEXT_PUBLIC_DISABLE_REGISTRATION = mkIf (!cfg.enableRegistration) "true";
      DATABASE_URL = mkIf isPostgresUnixSocket "postgresql://${lib.strings.escapeURL cfg.database.user}@localhost/${lib.strings.escapeURL cfg.database.name}?host=${cfg.database.host}";
      DATABASE_PORT = toString cfg.database.port;
      DATABASE_HOST = mkIf (!isPostgresUnixSocket) cfg.database.host;
      DATABASE_NAME = cfg.database.name;
      DATABASE_USER = cfg.database.user;
    };

    systemd.services.linkwarden = {
      description = "Linkwarden (Self-hosted collaborative bookmark manager to collect, organize, and preserve webpages, articles, and more...)";
      requires = [
        "network-online.target"
      ] ++ lib.optionals cfg.database.enable [ "postgresql.service" ];
      after = [
        "network-online.target"
      ] ++ lib.optionals cfg.database.enable [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = cfg.environment // {
        # Required, otherwise chrome dumps core
        CHROME_CONFIG_HOME = cfg.cacheLocation;
      };

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;

        ExecStart = lib.getExe cfg.package;
        EnvironmentFile = cfg.secretsFile;
        StateDirectory = "linkwarden";
        CacheDirectory = "linkwarden";
        User = cfg.user;
        Group = cfg.group;

        # Hardening
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateUsers = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateMounts = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };

    users.users = mkIf (cfg.user == "linkwarden") {
      linkwarden = {
        name = "linkwarden";
        group = cfg.group;
        isSystemUser = true;
      };
    };
    users.groups = mkIf (cfg.group == "linkwarden") { linkwarden = { }; };

    meta.maintainers = with lib.maintainers; [ jvanbruegge ];
  };
}
