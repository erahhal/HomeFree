{ config, lib, pkgs, ... }:
let
  hostConfig = ''
    respond "Hello, world! I am being accessed from {scheme}."
  '';
  proxiedHostConfig = config.homefree.proxied-hosts;
  homefree-site = pkgs.callPackage  ../site { };
  headscale-ui-config = lib.elemAt (lib.filter (proxy-config: proxy-config.label == "headscale-ui") config.homefree.proxied-hosts) 0;
  trimTrailingSlash = s: lib.head (lib.match "(.*[^/])[/]*" s);
in
{
  ## add homefree default site as a package
  nixpkgs.overlays = [
    (final: prev: {
      homefree-site = homefree-site;
    })
  ];

  systemd.services.caddy = {
    after = [ "network.target" "network-online.target" "unbound.service" ];
    requires = [ "network-online.target" "unbound.service" ];
  };

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    ## Temporarily set to staging
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";

    virtualHosts = lib.mkMerge [
      (lib.listToAttrs (lib.map (entry:
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
              # Add general security headers
              Strict-Transport-Security "max-age=31536000; includeSubdomains"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "strict-origin-when-cross-origin"
              X-XSS-Protection "1; mode=block"
            }
          '' + (if entry.basic-auth == true then ''
            basic_auth {
              # <username> <hash created with "caddy hash-password">
            }
          '' else "")
          + (if entry.public == false then ''
            bind 10.0.0.1
          '' else ''
            bind 10.0.0.1 ${config.homefree.system.domain}
          '')
          + (if entry.subdir != null then ''
            rewrite / ${trimTrailingSlash entry.subdir}{uri}
          '' else "")
          ## @TODO: throw an error if more than one host is using the same port
          + ''
            reverse_proxy ${if entry.ssl == true then  "https" else "http"}://${entry.host}:${toString entry.port} {
          ''
          + (if entry.ssl == true && entry.ssl-no-verify then ''
              transport http {
                tls
                tls_insecure_skip_verify
              }
          '' else "")
          + (if entry.basic-auth == true then ''
              header_up X-remote-user {http.auth.user.id}
          '' else "")
          +
          ''
            }
          '';
        };
      }
      ) proxiedHostConfig))
      {
        ## Needed so as to host ui and headscale enpoint on separate domains
        "https://headscale.${config.homefree.system.domain}" = {
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-headscale.log
          '';
          extraConfig = ''
            header {
              # Add general security headers
              Strict-Transport-Security "max-age=31536000; includeSubdomains"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "SAMEORIGIN"
              Referrer-Policy "strict-origin-when-cross-origin"
              X-XSS-Protection "1; mode=block"
            }

            reverse_proxy /web* http://10.0.0.1:3009
            reverse_proxy * http://10.0.0.1:8087
            bind 10.0.0.1 ${config.homefree.system.domain}
          '';
        };
      }

      # {
      #   ## Needed so as to host ui and headscale enpoint on separate domains
      #   "https://headscale.${config.homefree.system.domain}" = {
      #     logFormat = ''
      #       output file ${config.services.caddy.logDir}/access-headscale.log
      #     '';
      #     extraConfig = ''
      #       @headscale-options {
      #         host headscale.${config.homefree.system.domain}
      #         method OPTIONS
      #       }
      #       @headscale-other {
      #         host headscale.${config.homefree.system.domain}
      #       }
      #       handle @headscale-options {
      #         header {
      #           Access-Control-Allow-Origin https://headscale-ui.${config.homefree.system.domain}
      #           Access-Control-Allow-Headers *
      #           Access-Control-Allow-Methods "POST, GET, OPTIONS, DELETE"
      #         }
      #         respond 204
      #       }
      #       handle @headscale-other {
      #         reverse_proxy http://10.0.0.1:8087 {
      #           header_down Access-Control-Allow-Origin https://headscale-ui.${config.homefree.system.domain}
      #           header_down Access-Control-Allow-Methods "POST, GET, OPTIONS, DELETE"
      #           header_down Access-Control-Allow-Headers *
      #         }
      #     ''
      #     + (if headscale-ui-config.public == false then ''
      #         bind 10.0.0.1
      #     '' else ''
      #         bind 10.0.0.1 ${config.homefree.system.domain}
      #     '')
      #     + ''
      #       }
      #     '';
      #   };
      # }

      ## Static root site
      {
        "http://localhost, https://localhost, https://${config.homefree.system.domain}, https://www.${config.homefree.system.domain}" = {
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-landing-page.log
          '';
          extraConfig = ''
            bind 10.0.0.1 ${config.homefree.system.domain}
            root * ${config.homefree.landing-page.path}
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
          '';
        };
      }
    ];

    ## With both http and https set, caddy won't redirect http to https
    ## REMOVE THIS IN PROD
    # virtualHosts."http://localhost, https://localhost, https://${config.homefree.system.domain}, https://www.${config.homefree.system.domain}" = {
    #   # Nix config mangles the log name, so set it manually
    #   logFormat = ''
    #     output file ${config.services.caddy.logDir}/access-localhost.log
    #   '';
    #   extraConfig = hostConfig;
    # };

  };
}
