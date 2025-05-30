{ config, pkgs, ... }:
let
  version = "v2.10.2";
  version-meili = "v1.12.8";
  containerDataPath = "/var/lib/linkwarden-podman";

  port = 3005;
  database-name = "linkwarden";
  database-user = "linkwarden";

  preStart = ''
    mkdir -p ${containerDataPath}/linkwarden
    mkdir -p ${containerDataPath}/meili
  '';
in
{
  ## Copied from nixpkgs
  services.postgresql = if config.homefree.services.linkwarden.enable then {
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


  virtualisation.oci-containers.containers = if config.homefree.services.linkwarden.enable then {
    linkwarden = {
      image = "ghcr.io/linkwarden/linkwarden:${version}";

      dependsOn = [
        "meilisearch"
      ];

      autoStart = true;

      extraOptions = [
        # "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:3000"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/linkwarden:/data/data"
        "/run/postgresql:/run/postgresql"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
        DATABASE_URL = "postgresql://${database-user}@10.0.0.1:5432/${database-name}";
      };

      environmentFiles = [
        config.homefree.services.linkwarden.secrets.environment
      ];
    };

    meilisearch = {
      image = "getmeili/meilisearch:${version-meili}";

      autoStart = true;

      extraOptions = [
        # "--pull=always"
      ];

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${containerDataPath}/meili:/meili_data"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };

  } else {};

  systemd.services.podman-linkwarden = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf = [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "linkwarden-prestart" preStart}" ];
    };
  };

  systemd.services.podman-meilisearch = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    partOf =  [ "nftables.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "meili-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.linkwarden.enable == true then [
    {
      label = "linkwarden";
      name = "Bookmark Manager";
      project-name = "linkwarden";
      systemd-service-names = [
        "podman-linkwarden"
        "podman-meilisearch"
        "postgresql"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "links" "linkwarden" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.linkwarden.public;
      };
      backup = {
        paths = [
          "${containerDataPath}/linkwaren"
        ];
        postgres-databases = [
          database-name
        ];
      };
    }
  ] else [];
}
