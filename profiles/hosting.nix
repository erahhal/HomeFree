{ config, lib, pkgs, ... }:
let
  hostConfig = ''
    respond "Hello, world! I am being accessed from {scheme}."
  '';
  proxiedHostConfig = config.homefree.proxied-hosts;
in
{

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
            # header {
            #   Strict-Transport-Security "max-age=31536000; includeSubdomains"
            #   X-XSS-Protection "1; mode=block"
            #   X-Content-Type-Options "nosniff"
            #   X-Frame-Options "SAMEORIGIN"
            #   Referrer-Policy "same-origin"
            # }
          '' + (if entry.public == false then ''
            bind 10.0.0.1 192.168.2.1
          '' else ''
            bind 10.0.0.1 192.168.2.1 ${config.homefree.system.domain}
          '')
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

  };
}
