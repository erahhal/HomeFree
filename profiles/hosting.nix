{ config, pkgs, ... }:
let
  hostConfig = ''
    respond "Hello, world! I am being accessed from {scheme}."
  '';
in
{
  imports = [
    ../apps/radicale.nix
  ];

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    ## With both http and https set, caddy won't redirect http to https
    ## REMOVE THIS IN PROD
    virtualHosts."http://localhost, https://localhost" = {
      # Nix config mangles the log name, so set it manually
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-localhost.log
      '';
      extraConfig = hostConfig;
    };

    virtualHosts."http://authentik.homefree.lan, http://auth.homefree.lan" = {
      # Nix config mangles the log name, so set it manually
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-authentik.log
      '';
      ## @TODO: Remove headers and check if still works
      extraConfig = ''
        reverse_proxy http://10.1.1.1:9000
        header {
          Strict-Transport-Security "max-age=31536000; includeSubdomains"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          Referrer-Policy "same-origin"
        }
      '';
    };

    ## For use with LDAP
    # virtualHosts."http://ha.homefree.lan" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-homeassistant.log
    #   '';
      ## @TODO: Remove headers and check if still works
    #   extraConfig = ''
    #     reverse_proxy http://10.1.1.1:8123
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    virtualHosts."http://ha.homefree.lan" = {
      # Nix config mangles the log name, so set it manually
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-homeassistant.log
      '';
      ## @TODO: Remove headers and check if still works
      extraConfig = ''
        reverse_proxy http://10.1.1.1:9000
        header {
          Strict-Transport-Security "max-age=31536000; includeSubdomains"
          X-XSS-Protection "1; mode=block"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          Referrer-Policy "same-origin"
        }
      '';
    };

    virtualHosts."http://radicale.homefree.lan" = {
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-radicale.log
      '';
      extraConfig = ''
        reverse_proxy :5232
      '';
    };
  };
}
