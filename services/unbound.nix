{ homefree-inputs, config, lib, pkgs, ... }:
let
  adlist = homefree-inputs.adblock-unbound.packages.${pkgs.system};
  proxiedHostConfig = lib.filter (service-config: service-config.reverse-proxy.enable == true) config.homefree.service-config;
  zones = [config.homefree.system.domain] ++ config.homefree.system.additionalDomains;
  preStart = ''
    touch /run/unbound/include.conf
    cat > /run/unbound/dynamic.zone<< EOF
    \$ORIGIN ${config.homefree.system.localDomain}.
    \$TTL 3600
    @       IN      SOA     localhost. root.localhost. (
                            2023100101 ; serial
                            3600       ; refresh
                            1800       ; retry
                            604800     ; expire
                            86400      ; minimum
                            )
            IN      NS      localhost.
    EOF
    # cp /run/unbound/dynamic.zone /tmp
  '';
in
{
  ## See: https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

  ## Unbound is a caching resolver, not meant to be used as authoritative.
  ## nbound does support simple authoritative hosting with local-zone config.
  ## For a proper authoritative DNS, look at NSD.

  systemd.services.unbound = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "unbound-prestart" preStart}" ];
    };
  };

  services.unbound = {
    enable = true;

    user = "root";

    resolveLocalQueries = true;

    settings = {
      ## Make Unbound default DNS server if adguard is disabled
      server = {
        port = if config.homefree.services.adguard.enable == true
        then
          53530
        else
          53
        ;
        include = [
          ## Leave ad-blocking to AdGuard, as it can be disabled by the client
          # "\"${adlist.unbound-adblockStevenBlack}\""

          ## Include run-time config, such as WAN ip mappings
          ## @TODO: Update this with ddclient scripts
          ## @TODO: Remove WAN entries from bare hostname maps below
          "\"/run/unbound/include.conf\""
        ];
        ## Set in services/adguardhome.nix
        ## if adguard is disabled, this is set to 53 to make it the default DNS
        # port = 53530;
        interface = [
          "127.0.0.1"
          "::1"
          "10.0.0.1"
          "100.64.0.2"       # headscale
        ];
        access-control = [
          "127.0.0.1/24 allow"
          "::1 allow"
          "10.0.0.1/24 allow"
          "100.64.0.2/24 allow"
        ];
        # outgoing-interface = [
        #   ## @TODO: should be WAN IP - how to get this automatically?
        #   "10.0.2.15"
        #   # @TODO: need ipv6 address
        # ];
        local-zone = [
          "\"homefree.lan\" static"
          "\"homefree.host\" transparent"
          "\"rahh.al\" transparent"
        ];
        ## @TODO: Add config.homefree.network.blocked-domains as such:
        # local-zone: "example.org" always_nxdomain

        ## Record format:
        ## NAME             CLASS (default: IN)   TYPE  RDATA
        ## localhost        IN                    A     127.0.0.1
        local-data =
        [
          "\"localhost A 127.0.0.1\""
          "\"localhost AAAA ::1\""
        ]
        ++
        ## add localhost.<zone> for all configured zones
        (lib.map (zone: "\"localhost.${zone} IN A 127.0.0.1\"") zones)
        ++
        ## add <hostname>.<zone> for all configured zones
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 127.0.0.1\"") zones)
        ++
        # Add DNS overrides
        (lib.map (local-data-config:
          if builtins.hasAttr "domain" local-data-config then
            "\"${local-data-config.hostname}.${local-data-config.domain} IN A ${local-data-config.ip}\""
          else
            "\"${local-data-config.hostname} IN A ${local-data-config.ip}\""
          ) config.homefree.network.dns-overrides
        )
        ++
        # Point proxy URLs to internal IP when on LAN
        (lib.map
          (fqn: "\"${fqn} IN A 10.0.0.1\"")
          ## Flatten to single list
          ## e.g. [ "hij.lmnop" "hij.xyz" "abc.lmnop" "abc.xyz"  "def.lmnop" "def.xyz" ]
          (lib.flatten
            ## Map across all proxy configs
            ## creating list of lists
            ## e.g. [ [ "hij.lmnop" "hij.xyz" ] [ "abc.lmnop" "abc.xyz"  "def.lmnop" "def.xyz" ] ]
            (lib.map
              (service-config:
                ## Flatten subdomain-domain combinations for individual proxy into single list
                ## e.g. [ "abc.lmnop" "abc.xyz"  "def.lmnop" "def.xyz" ]
                lib.flatten
                ## Create all subdomain-domain combinations, grouped by subdomain
                ## e.g. [ [ "abc.lmnop" "abc.xyz" ] [ "def.lmnop" "def.xyz" ]]
                (lib.map
                  (subdomain:
                    # Create <subdomain>.<domain> fqn string
                    (lib.map
                      (domain: "${subdomain}.${domain}")
                      (service-config.reverse-proxy.http-domains ++ service-config.reverse-proxy.https-domains)
                    )
                  )
                  service-config.reverse-proxy.subdomains
                )
              )
              ## @TODO: Get rid of this filter
              ## See: https://caddy.community/t/caddy-not-handling-requests-when-listening-on-all-interfaces-serving-a-hostname-mapped-to-an-internal-ip/26384
              # (lib.filter (proxy-config: proxy-config.public == false) proxiedHostConfig)
              proxiedHostConfig
            )
          )
        )
        ++
        ## router lan ip with public domains
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 10.0.0.1\"") zones)
        ++
        ## @TODO: Move to config for gateway IP
        [
          ## router lan IP
          "\"${config.homefree.system.hostName} IN A 10.0.0.1\""
          ## router lan IP with local domain
          "\"${config.homefree.system.hostName}.${config.homefree.system.localDomain} IN A 10.0.0.1\""
        ]
        ++
        ## @TODO: How to configure these at runtime?
        ## router wan IP with public domain
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 104.182.229.64\"") zones)
        ++
        ## Bare hostname maps
        [
          ## router wan IP - @TODO - THIS NEEDS TO BE DYNAMIC
          "\"${config.homefree.system.hostName} IN A 104.182.229.64\""
          ## router wan ipv6 IP - @TODO - THESE ARE WRONG
          "\"${config.homefree.system.hostName} IN AAAA 2600:1700:ab00:4650:2e0:67ff:fe22:3e62\""
          ## ??? @TODO - WHAT IS THIS?
          "\"${config.homefree.system.hostName} IN AAAA 2600:1700:ab00:465f:2e0:67ff:fe22:3e63\""
        ]
        ++
        ## router wan IPv6 with public domain
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN AAAA 2600:1700:ab00:4650:2e0:67ff:fe22:3e62\"") zones)
        ++
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN AAAA 2600:1700:ab00:465f:2e0:67ff:fe22:3e64\"") zones)
        ++
        (lib.map (ip-config:
        "\"${ip-config.hostname} IN A ${ip-config.ip}\"")
        config.homefree.network.static-ips)
        ++
        (lib.map (ip-config:
        "\"${ip-config.hostname}.${config.homefree.system.localDomain} IN A ${ip-config.ip}\"")
        config.homefree.network.static-ips)
        ;

        local-data-ptr = [
          "\"::1 localhost\""
          "\"127.0.0.1 localhost\""
        ]
        ++
        (lib.map (ip-config:
        "\"${ip-config.ip} ${ip-config.hostname}\"")
        config.homefree.network.static-ips)
        ++
        (lib.map (ip-config:
        "\"${ip-config.ip} ${ip-config.hostname}.${config.homefree.system.localDomain}\"")
        config.homefree.network.static-ips)

        ## @TODO: Add caddy domains to zones, e.g.:
        ## "10.0.0.1 auth.rahh.al"
        ;

        hide-identity = true;
        hide-version = true;

        # Based on recommended settings in https://doc.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;
      };
      #
      # range-lan = {
      #   start = "10.0.0.200";
      #   end = "10.0.0.254";
      #   domain = config.homefree.system.localDomain;
      # };

      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "9.9.9.9#dns.quad9.net"
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
          forward-tls-upstream = "yes";
        }
        # {
        #   name = "example.org.";
        #   forward-addr = [
        #     "1.1.1.1@853#cloudflare-dns.com"
        #     "1.0.0.1@853#cloudflare-dns.com"
        #   ];
        # }
      ];

      ## Enable dynamic updates from dnsmasq
      auth-zone = {
        name = "\"${config.homefree.system.localDomain}\"";
        master = "yes";
        allow-notify = "no";
        for-downstream = "no";
        for-upstream = "yes";
        zonefile = "\"/run/unbound/dynamic.zone\"";
      };

      remote-control.control-enable = true;
    };
  };
}
