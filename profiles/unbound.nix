{ homefree-inputs, config, lib, pkgs, ... }:
let
  adlist = homefree-inputs.adblock-unbound.packages.${pkgs.system};
  zones = [config.homefree.system.domain] ++ config.homefree.system.additionalDomains;
in
{
  ## See: https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

  ## Unbound is a caching resolver, not meant to be used as authoritative.
  ## nbound does support simple authoritative hosting with local-zone config.
  ## For a proper authoritative DNS, look at NSD.

  services.unbound = {
    enable = true;

    user = "root";

    resolveLocalQueries = true;

    settings = {
      server = {
        include = [
          "\"${adlist.unbound-adblockStevenBlack}\""
        ];
        port = 53530;
        interface = [
          "127.0.0.1"
          "::1"
          "10.1.1.1"
        ];
        access-control = [
          "127.0.0.1/8 allow"
          "::1 allow"
          "10.1.1.1/8 allow"
          # @TODO: need ipv6 address
        ];
        outgoing-interface = [
          ## @TODO: should be WAN IP - how to get this automatically?
          "10.0.2.15"
          # @TODO: need ipv6 address
        ];
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
        (lib.map (zone: "\"localhost.${zone} IN A 127.0.0.1\"") zones)
        ++
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 127.0.0.1\"") zones)
        ++
        (lib.map (local-data-config:
          if builtins.hasAttr "domain" local-data-config then
            "\"${local-data-config.hostname}.${local-data-config.domain} IN A ${local-data-config.ip}\""
          else
            "\"${local-data-config.hostname} IN A ${local-data-config.ip}\""
          ) config.homefree.network.dns-overrides
        )
        ++
        ## router lan ip with public domains
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 10.0.0.1\"") zones)
        ++
        ## router vpn ip with public domains
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 192.168.2.1\"") zones)
        ++
        ## @TODO: Move to config for gateway IP
        [
          ## router lan IP
          "\"${config.homefree.system.hostName} IN A 10.0.0.1\""
          ## router lan IP with local domain
          "\"${config.homefree.system.hostName}.${config.homefree.system.localDomain} IN A 10.0.0.1\""

          ## router vpn IP
          "\"${config.homefree.system.hostName} IN A 192.168.2.1\""
          ## router vpn IP with local domain
          "\"${config.homefree.system.hostName}.${config.homefree.system.localDomain} IN A 192.168.2.1\""
        ]
        ++
        ## @TODO: How to configure these at runtime?
        ## router wan IP with public domain
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN A 104.182.229.64\"") zones)
        ++
        ## Bare hostname maps
        [
          ## router wan IP
          "\"${config.homefree.system.hostName} IN A 104.182.229.64\""
          ## router wan ipv6 IP
          "\"${config.homefree.system.hostName} IN AAAA 2600:1700:ab00:4650:2e0:67ff:fe22:3e62\""
          ## ??
          "\"${config.homefree.system.hostName} IN AAAA 2600:1700:ab00:465f:2e0:67ff:fe22:3e63\""
        ]
        ++
        ## router wan IPv6 with public domain
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN AAAA 2600:1700:ab00:4650:2e0:67ff:fe22:3e62\"") zones)
        ++
        (lib.map (zone: "\"${config.homefree.system.hostName}.${zone} IN AAAA 2600:1700:ab00:465f:2e0:67ff:fe22:3e64\"") zones)
        ++
        (lib.map (ip-config:
        "\"${ip-config.hostname}.${config.homefree.system.localDomain} IN A ${ip-config.ip}\"")
        config.homefree.network.static-ips)

        ## @TODO: Add caddy domains to zones, e.g.:
        ## "auth.rahh.al IN A 10.0.0.1"
        ;

        local-data-ptr = [
          "\"::1 localhost\""
          "\"127.0.0.1 localhost\""
        ]
        ++
        (lib.concatLists
          (lib.map (zone:
            (lib.map (ip-config: "\"${ip-config.ip} ${ip-config.hostname}.${zone}\"") config.homefree.network.static-ips)
          ) zones)
        )

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
      #   domain = "localdomain";
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

      remote-control.control-enable = true;
    };
  };
}
