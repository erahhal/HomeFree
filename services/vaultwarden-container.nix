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
