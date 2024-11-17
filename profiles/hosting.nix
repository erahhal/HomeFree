{ config, lib, pkgs, ... }:
let
  hostConfig = ''
    respond "Hello, world! I am being accessed from {scheme}."
  '';
  proxiedHostConfig = config.homefree.proxied-hosts;
in
{
  imports = [
    ../apps/radicale.nix
  ];

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    ## Temporarily set to staging
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";

    virtualHosts = lib.listToAttrs (lib.map (entry:
      let
        http-urls = lib.flatten (lib.map (subdomain: (lib.map (domain: "http://${subdomain}.${domain}") entry.http-domains)) entry.subdomains);
        https-urls = lib.flatten (lib.map (subdomain: (lib.map (domain: "https://${subdomain}.${domain}") entry.https-domains)) entry.subdomains);
        urls = http-urls ++ https-urls;
        host-string = lib.concatStringsSep ", " urls;
      in {
        name = host-string;
        value = {
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-${entry.label}.log
          '';
          ## @TODO: Remove headers and check if still works
          extraConfig = ''
            header {
              Strict-Transport-Security "max-age=31536000; includeSubdomains"
              X-XSS-Protection "1; mode=block"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "same-origin"
            }
          '' + (if entry.public == false then ''
            bind 10.0.0.1
          '' else "")
          + (if entry.ssl == true && entry.ssl-no-verify then ''
            reverse_proxy https://${entry.host}:${toString entry.port} {
              transport http {
                tls
                tls_insecure_skip_verify
              }
            }
          '' else ''
            reverse_proxy ${if entry.ssl == true then  "https" else "http"}://${entry.host}:${toString entry.port}
          '');
        };
      }
    ) proxiedHostConfig);

    ## With both http and https set, caddy won't redirect http to https
    ## REMOVE THIS IN PROD
    # virtualHosts."http://localhost, https://localhost, https://${config.homefree.system.domain}, https://www.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-localhost.log
    #   '';
    #   extraConfig = hostConfig;
    # };

    # virtualHosts."http://authentik.homefree.lan, http://auth.homefree.lan, https://authentik.${config.homefree.system.domain}, https://auth.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-authentik.log
    #   '';
    #   ## @TODO: Remove headers and check if still works
    #   extraConfig = ''
    #     reverse_proxy http://127.0.0.1:9000
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://vaultwarden.homefree.lan, https://vaultwarden.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-vaultwarden.log
    #   '';
    #   extraConfig = ''
    #     reverse_proxy http://127.0.0.1:8222
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };
    #
    # ## For use with LDAP
    # virtualHosts."http://ha.homefree.lan, https://ha.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-homeassistant.log
    #   '';
    #   # @TODO: Remove headers and check if still works
    #   extraConfig = ''
    #     reverse_proxy http://127.0.0.1:8123
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # ## For use with LDAP
    # virtualHosts."https://ha.rahh.al" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-homeassistant-old.log
    #   '';
    #   # @TODO: Remove headers and check if still works
    #   extraConfig = ''
    #     bind 10.0.0.1
    #     reverse_proxy http://homeassistant.localdomain:8123
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://ha.homefree.lan, https://ha.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-homeassistant.log
    #   '';
    #   ## @TODO: Remove headers and check if still works
    #   extraConfig = ''
    #     ## Authentik
    #     reverse_proxy http://127.0.0.1:9000
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://git.homefree.lan, https://git.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-git.log
    #   '';
    #   extraConfig = ''
    #     reverse_proxy http://127.0.0.1:3001
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://adguard.homefree.lan, https://adguard.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-adguard.log
    #   '';
    #   extraConfig = ''
    #     reverse_proxy http://127.0.0.1:3000
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://unifi.homefree.lan, https://unifi.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-unifi.log
    #   '';
    #   extraConfig = ''
    #     reverse_proxy https://127.0.0.1:8443 {
    #       transport http {
    #         tls
    #         tls_insecure_skip_verify
    #       }
    #     }
    #     header {
    #       Strict-Transport-Security "max-age=31536000; includeSubdomains"
    #       X-XSS-Protection "1; mode=block"
    #       X-Content-Type-Options "nosniff"
    #       X-Frame-Options "SAMEORIGIN"
    #       Referrer-Policy "same-origin"
    #     }
    #   '';
    # };

    # virtualHosts."http://radicale.homefree.lan, https://radicale.${config.homefree.system.domain}" = {
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-radicale.log
    #   '';
    #   extraConfig = ''
    #     reverse_proxy :5232
    #   '';
    # };
  };
}
