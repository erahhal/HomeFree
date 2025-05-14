{ config, pkgs, ... }:
let
  version = "9.1.120";
  containerDataPath = "/var/lib/unifi-podman";
  port = 8443;
  MONGO_AUTHSOURCE = "admin";
  MONGO_INITDB_ROOT_USERNAME = "root";
  MONGO_INITDB_ROOT_PASSWORD = "password";
  MONGO_USER = "unifi";
  MONGO_PASS = "password";
  MONGO_HOST = "unifi-db";
  MONGO_PORT = "27017";
  MONGO_DBNAME = "unifi";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';

  ## tag 8.0 changes
  ## Use patch version for stability, e.g. "8.0.9"
  mongo-version = "8.0";
  mongo-containerDataPath = "/var/lib/unifi-db-podman";

  mongo-preStart = ''
    mkdir -p ${mongo-containerDataPath}
  '';

  init-unifi-db = pkgs.writeShellScriptBin "init-unifi-db" ''
    if which mongosh > /dev/null 2>&1; then
      mongo_init_bin='mongosh'
    else
      mongo_init_bin='mongo'
    fi
    $mongo_init_bin <<EOF
    use ${MONGO_AUTHSOURCE}
    db.auth("${MONGO_INITDB_ROOT_USERNAME}", "${MONGO_INITDB_ROOT_PASSWORD}")
    db.createUser({
      user: "${MONGO_USER}",
      pwd: "${MONGO_PASS}",
      roles: [
        { db: "${MONGO_DBNAME}", role: "dbOwner" },
        { db: "${MONGO_DBNAME}_stat", role: "dbOwner" },
        { db: "${MONGO_DBNAME}_audit", role: "dbOwner" }
      ]
    })
    EOF
  '';
in
{
  virtualisation.oci-containers.containers = if config.homefree.services.unifi.enable == true then {
    unifi-db = {
      image = "mongo:${mongo-version}";
      # image = "mongodb/mongodb-community-server:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:27017:27017"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${mongo-containerDataPath}:/data/db"
        "${init-unifi-db}/bin/init-unifi-db:/docker-entrypoint-initdb.d/init-mongo.sh:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        MONGO_INITDB_ROOT_USERNAME = MONGO_INITDB_ROOT_USERNAME;
        MONGO_INITDB_ROOT_PASSWORD = MONGO_INITDB_ROOT_PASSWORD;
        MONGO_USER = MONGO_USER;
        MONGO_PASS = MONGO_PASS;
        MONGO_DBNAME = MONGO_DBNAME;
        MONGO_AUTHSOURCE = MONGO_AUTHSOURCE;
      };
    };

    unifi = {
      image = "lscr.io/linuxserver/unifi-network-application:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        ## Web interface
        "0.0.0.0:${toString port}:${toString port}"

        ## STUN port - only necessary if controlling devices behind a firewall
        ## Disabled to not conflict with Headscale DERP
        # "0.0.0.0:3478:3478/udp"

        ## Device discover during adoption
        "0.0.0.0:10001:10001/udp"

        ## Device and application communication
        "0.0.0.0:8080:8080"

        ## Used with "Make application discoverable on L2 network" in the UniFi Network settings.
        "0.0.0.0:1900:1900/udp" #optional

        ## Used for HTTPS portal redirection. (only needed if using Guest hotspot)
        "0.0.0.0:8843:8843"     #optional

        ## Hotspot portal redirection (HTTP).
        "0.0.0.0:8880:8880"     #optional

        ## UniFi mobile speed test.
        "0.0.0.0:6789:6789"     #optional

        ## Used for remote syslog capture.
        "0.0.0.0:5514:5514/udp" #optional
      ];

      volumes = [
        "${containerDataPath}:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        PUID = "1000";
        PGID = "1000";
        MONGO_USER = MONGO_USER;
        MONGO_PASS = MONGO_PASS;
        MONGO_HOST = MONGO_HOST;
        MONGO_PORT = MONGO_PORT;
        MONGO_DBNAME = MONGO_DBNAME;
        MONGO_AUTHSOURCE = MONGO_AUTHSOURCE;
        MEM_LIMIT = "1024"; #optional
        MEM_STARTUP = "1024"; #optional
        MONGO_TLS = ""; #optional
      };
    };
  } else {};

  systemd.services.podman-unifi-db = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "unifi-db-prestart" mongo-preStart}" ];
    };
  };

  systemd.services.podman-unifi = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "unifi-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.unifi.enable == true then [
    {
      label = "unifi";
      name = "Unifi Controller";
      project-name = "Unifi Controller";
      systemd-service-names = [
        "podman-unifi"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "unifi" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.unifi.public;
      };
      backup = {
        paths = [
          containerDataPath
          mongo-containerDataPath
        ];
      };
    }
  ] else [];
}

