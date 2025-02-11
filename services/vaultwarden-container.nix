{ config, homefree-inputs, ... }:
let
  enable = config.homefree.services.vaultwarden.enable;
  port = 8222;
  backup-path = "/var/backup/vaultwarden";
in
{
  containers.vaultwarden = {
    nixpkgs = homefree-inputs.nixpkgs-unstable;
    autoStart = true;
    ephemeral = false;
    config = { config, pkgs, lib, ... }: {
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };
      services.vaultwarden = {
        enable =  enable;
        dbBackend = "sqlite";   # "sqlite", "mysql", "postgresql"
        backupDir = backup-path;
        config = {
          ROCKET_ADDRESS = "10.0.0.1";
          ROCKET_PORT = port;
        };
      };
    };
  };

  homefree.service-config = if config.homefree.services.vaultwarden.enable == true then [
    {
      label = "vaultwarden";
      name = "Password Manager";
      project-name = "Vaultwarden";
      systemd-service-names = [
        "vaultwarden"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "vaultwarden" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.vaultwarden.public;
      };
      backup = {
        paths = [
          "/var/lib/nixos-containers${backup-path}"
        ];
      };
    }
  ] else [];
}
