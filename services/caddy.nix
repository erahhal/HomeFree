{ config, lib, pkgs, ... }:
let
  proxiedHostConfig = lib.filter (service-config: service-config.reverse-proxy.enable == true) config.homefree.service-config;
  trimTrailingSlash = s: lib.head (lib.match "(.*[^/])[/]*" s);
in
{
  systemd.services.caddy = {
    wants = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
  };

  ## Restart Unbound DNS with caddy changes
  systemd.services.unbound = {
    partOf = [ "caddy.service" ];
    before = [ "caddy.service" ] ++ (if config.homefree.services.adguard.enable == true then [ "adguardhome.service" ] else []);
  };

  ## Restart Adguard DNS with caddy changes
  systemd.services.adguardhome = if config.homefree.services.adguard.enable == true then {
    partOf = [ "unbound.service" ];
  } else {};

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    ## Temporarily set to staging
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";

    virtualHosts = lib.mkMerge [
      (lib.listToAttrs (lib.map (service-config:
      let
        reverse-proxy-config = service-config.reverse-proxy;
        http-urls = lib.flatten (lib.map (subdomain: (lib.map (domain: "http://${subdomain}.${domain}") reverse-proxy-config.http-domains)) reverse-proxy-config.subdomains);
        https-urls = lib.flatten (lib.map (subdomain: (lib.map (domain: "https://${subdomain}.${domain}") reverse-proxy-config.https-domains)) reverse-proxy-config.subdomains);
        http-urls-root-domain = if reverse-proxy-config.rootDomain == true then (lib.map (domain: "http://${domain}") reverse-proxy-config.http-domains) else [];
        https-urls-root-domain = if reverse-proxy-config.rootDomain == true then (lib.map (domain: "https://${domain}") reverse-proxy-config.https-domains) else [];
        urls = http-urls ++ https-urls ++ http-urls-root-domain ++ https-urls-root-domain;
        host-string = lib.concatStringsSep ", " urls;
      in {
        name = host-string;
        value = {
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-${service-config.label}.log
          '';
          ## @TODO: Remove headers and check if still works
          extraConfig = ''
            header {
              # Add general security headers
              Strict-Transport-Security "max-age=31536000; includeSubdomains"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "strict-origin-when-cross-origin"
              X-XSS-Protection "1; mode=block"
            }
          '' + (if reverse-proxy-config.basic-auth == true then ''
            basic_auth {
              # <username> <hash created with "caddy hash-password">
            }
          '' else "")
          + (if reverse-proxy-config.public == false then ''
            bind 10.0.0.1
          '' else ''
            bind 10.0.0.1 ${config.homefree.system.domain} ::
          '')
          + (if reverse-proxy-config.subdir != null then ''
            rewrite / ${trimTrailingSlash reverse-proxy-config.subdir}{uri}
          '' else "")
          ## @TODO: throw an error if more than one host is using the same port
          + (if reverse-proxy-config.static-path != null then ''
            root * ${reverse-proxy-config.static-path}
            file_server

            # Enable Gzip compression
            encode gzip

            # HTML files - No caching to ensure fresh content
            @html {
            file
              path *.html
            }
            header @html {
              # Disable caching for HTML
              Cache-Control "no-cache, must-revalidate"
              # Add ETag for conditional requests
              ETag
              # Add Last-Modified header
              +Last-Modified
            }

            # CSS files - Aggressive caching with revalidation
            @css {
              file
              path *.css
            }
            header @css {
              # Cache for 1 year, but allow revalidation
              Cache-Control "public, max-age=31536000, stale-while-revalidate=86400"
              ETag
              +Last-Modified
              Vary Accept-Encoding
            }

            # Assets (CSS, JS, images)
            @assets {
              file
              path *.js *.png *.jpg *.jpeg *.gif *.svg *.woff *.woff2
            }
            header @assets {
              # Cache for 1 hour, but allow revalidation
              Cache-Control "public, max-age=3600, must-revalidate"
              # Add ETag for conditional requests
              ETag
              # Add Last-Modified header
              +Last-Modified
              # Add Vary header to handle different client capabilities
              Vary Accept-Encoding
            }

            # General headers
            header {
              # Remove Server header for security
              -Server
              # Add general security headers
              Strict-Transport-Security "max-age=31536000; includeSubdomains"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "strict-origin-when-cross-origin"
              X-XSS-Protection "1; mode=block"
            }
          '' else (''
            reverse_proxy ${if reverse-proxy-config.ssl == true then  "https" else "http"}://${reverse-proxy-config.host}:${toString reverse-proxy-config.port} {
          ''
          + (if reverse-proxy-config.ssl == true && reverse-proxy-config.ssl-no-verify then ''
              transport http {
                tls
                tls_insecure_skip_verify
              }
          '' else "")
          + (if reverse-proxy-config.basic-auth == true then ''
              header_up X-remote-user {http.auth.user.id}
          '' else "")
          +
          ''
            }
          ''))
          + (if reverse-proxy-config.extraCaddyConfig != null then reverse-proxy-config.extraCaddyConfig else "");
        };
      }
      ) proxiedHostConfig))
    ];
  };
}
