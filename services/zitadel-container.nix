{ config, homefree-inputs, ... }:
let
  enable = config.homefree.services.zitadel.enable;
  domain = config.homefree.system.domain;
  port = 8678;
in
{
  containers.zitadel = {
    nixpkgs = homefree-inputs.nixpkgs-unstable;
    autostart = true;
    ephemeral = false;
    config = { config, pkgs, lib, ... }: {
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };
      services.zitadel = {
        enable = enable;
        tlsMode= "external";
        # masterKeyFile = <path> # 32 bytes

        settings = {
          Port = port;
          ExternalDomain = domain;
          TLS = {
            CertPath = "/path/to/cert.pem";
            KeyPath = "/path/to/cert.key";
          };
          Database.cockroach.Host = "db.example.com";
        };
      };
    };
  };

  homefree.service-config = if config.homefree.services.zitadel.enable == true then [
    {
      label = "zitadel";
      name = "Zitadel auth";
      project-name = "Zitadel";
      systemd-service-names = [
        "zitadel"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "zitadel" ];
        http-domains = [ "homefree.lan" config.homefree.system.localdomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.unifi.public;
      };
      backup = {
        paths = [
          ## @todo: how to programmatically set backup frequency? unifi ui defaults to monthly.
          "/var/lib/nixos-containers/var/lib/unifi/data/backup"
        ];
      };
    }
  ] else [];
}


