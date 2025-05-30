{ config, pkgs, ... }:
let
  ## tag 8.0 changes
  ## Use patch version for stability, e.g. "8.0.9"
  version = "8.0";
  containerDataPath = "/var/lib/mongo-podman";

  preStart = ''
    mkdir -p ${containerDataPath}
  '';
in
{
  virtualisation.oci-containers.containers.mongo = {
    image = "mongo:${version}";
    # image = "mongodb/mongodb-community-server:${version}";

    autoStart = true;

    extraOptions = [
      # "--pull=always"
    ];

    ports = [
      "0.0.0.0:27017:27017"
    ];

    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${containerDataPath}:/data/db"
    ];

    environment = {
      TZ = config.homefree.system.timeZone;
      MONGO_INITDB_ROOT_USERNAME = "root";
      MONGO_INITDB_ROOT_PASSWORD = "password";
    };
  };

  systemd.services.podman-mongo = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "mongo-prestart" preStart}" ];
    };
  };
}

