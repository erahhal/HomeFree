{ config, homefree-inputs, ... }:
let
  enable = config.homefree.services.unifi.enable;
in
{
  containers.unifi = {
    nixpkgs = homefree-inputs.nixpkgs-unstable;
    autoStart = true;
    ephemeral = false;
    config = { config, pkgs, lib, ... }: {
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };
      nixpkgs.config.allowUnfree = true;
      services.unifi = {
        enable = enable;
        openFirewall = true;
        ## Don't use closed source version. CE version is cached.
        mongodbPackage = pkgs.mongodb-ce;
      };
    };
  };

  homefree.service-config = if config.homefree.services.unifi.enable == true then [
    {
      label = "unifi";
      name = "Unifi Controller";
      project-name = "Unifi Controller";
      systemd-service-names = [
        "unifi"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "unifi" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 8443;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.unifi.public;
      };
      backup = {
        paths = [
          ## @TODO: how to programmatically set backup frequency? Unifi UI defaults to monthly.
          "/var/lib/nixos-containers/var/lib/unifi/data/backup"
        ];
      };
    }
  ] else [];
}

