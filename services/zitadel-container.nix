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
    config = { config, lib, ... }: {
      imports = [
        # https://github.com/NixOS/nixpkgs/issues/393637
        ../provisional/hypothesis.nix
      ];
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        # sets up an isolated environment for each build process to improve reproducibility.
        # Disallow network callsoutside of fetch* and files outside of the Nix store.
        sandbox = true;
        # Automatically clean out old entries from nix store by detecting duplicates and creating hard links.
        # Only starts with new derivations, so run "nix-store --optimise" to clear out older cruft.
        # optimise.automatic = true below should handle this.
        auto-optimise-store = true;
        # Users with additional Nix daemon rights.
        # Can specify additional binary caches, import unsigned NARs (Nix Archives).
        trusted-users = [ "@wheel" "root" ];
        # Users allowed to connect to Nix daemon
        allowed-users = [ "@wheel" ];
        substituters = [
          "https://cache.nixos.org"
          "https://hydra.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
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


