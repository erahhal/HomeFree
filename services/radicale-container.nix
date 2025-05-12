{ config, homefree-inputs, ... }:
let
  enable = config.homefree.services.radicale.enable;
in
{
  containers.radicale = {
    nixpkgs = homefree-inputs.nixpkgs-unstable;
    autoStart = true;
    ## Don't use overlay FS
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
      services.radicale = {
        enable =  enable;
        settings = {
          server.hosts = [ "10.0.0.1:5232" ];

          auth = {
            type = "none";
          };

          # auth = {
          #   type = "http_x_remote_user";
          # };

          # auth = {
          #   type = "htpasswd";
          #   htpasswd_filename = "/var/lib/radicale/htpasswd";
          #   # hash function used for passwords. May be `plain` if you don't want to hash the passwords
          #   htpasswd_encryption = "bcrypt";
          # };
        };
      };
    };
  };

  homefree.service-config = if config.homefree.services.radicale.enable == true then [
    {
      label = "radicale";
      name = "Contacts/Calendar (CalDAV/CardDAV)";
      project-name = "Radicale";
      systemd-service-names = [
        "radicale"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "radicale" "dav" "webdav" "caldav" "carddav" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 5232;
        public = config.homefree.services.radicale.public;
        # basic-auth = true;
      };
      backup = {
        paths = [
          "/var/lib/nixos-containers/radicale/var/lib/radicale"
        ];
      };
    }
  ] else [];
}
