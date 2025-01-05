{ config, lib, pkgs, ... }:
let
  cfg = config.homefree;
  search-domains = [ cfg.system.domain cfg.system.localDomain ] ++ cfg.system.additionalDomains;
  ## See: https://headscale.net/stable/ref/acls/
  ## @TODO: Doesn't seem to work, may even block all traffic not explicitly approved.
  policy = pkgs.writeText "headscale-policy.json" ''
  {
    "hosts": {
      "homefree.lan": "10.0.0.1/32"
    },
    "autoApprovers": {
      "routes": {
        "10.0.0.0/24": [
          "homefree.lan"
        ]
      }
    }
  }
  '';
in
{
  environment.systemPackages = [
    pkgs.headscale
    pkgs.tailscale
  ];

  services.headscale = {
    enable = config.homefree.services.headscale.enable;
    port = 8087;
    address = "10.0.0.1";
    settings = {
      server_url = "https://headscale.${cfg.system.domain}:443";
      # policy.path = policy;
      dns = {
        magic_dns = true;
        ## Must be different from server domain
        base_domain = "homefree.vpn";
        # search_domains = search-domains;
        ## Add
        nameservers.global = [
          ## @TODO: It appears that these servers are round-robinned.
          ##        Can 10.0.0.1 be set as default, and the rest as backups?
          ##        Would be useful to support ad blocking over tailscale.

          ## Internal DNS, has local domain names
          # "10.0.0.1"

          ## Backup in case internal DNS not accessible due to connectivity issues
          "9.9.9.10"
          ## Secondary backup
          "1.1.1.1"
        ];
        nameservers.split = lib.listToAttrs (lib.map (domain:
          {
            name = domain;
            value = [
              "10.0.0.1"
            ];
          }
        ) search-domains);
      };
      prefixes = {
        ## Some VPNs use addresses that overlap. Reduce the size of the network
        ## from 10.64.0.0/10
        v4 = "100.64.0.0/24";
        v6 = "fd7a:115c:a1e0::/48";
      };
      derp = {
        server = {
          enabled = true;
          region_id = 999;
          region_code = "headscale";
          region_name = "headscale Embedded DERP";
          stun_listen_addr = "0.0.0.0:${toString cfg.services.headscale.stun-port}";
          automatically_add_embedded_derp_region = true;
        };
        ## Disable default DERP pointing at tailscale corporate servers
        urls = [ ];
      };
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.homefree.services.headscale.secrets.tailscale-key;
    authKeyParameters = {
      preauthorized = true;
      baseURL = "https://headscale.${config.homefree.system.domain}";
    };
    useRoutingFeatures = "server";
    extraUpFlags = [
      # "--advertise-routes=10.0.0.0/24,100.64.0.0/24"
      "--advertise-routes=10.0.0.0/24"
      # "--netfilter-mode=nodivert"
    ];
    extraSetFlags = [
      # "--advertise-routes=10.0.0.0/24,100.64.0.0/24"
      "--advertise-routes=10.0.0.0/24"
      # "--netfilter-mode=nodivert"
    ];
  };

  systemd.services.headscale-enable-routes = {
    after = [ "network.target" "network-online.target" "tailscale.service" ];
    requires = [ "network-online.target" "tailscaled.service" "tailscaled-set.service" "tailscaled-autoconnect.service" ];
    enable = true;
    serviceConfig = {
      User = "headscale";
    };
    # script = builtins.readFile ../scripts/tune_router_performance.sh;
    script = ''
      HEADSCALE=${pkgs.headscale}/bin/headscale
      GREP=${pkgs.gnugrep}/bin/grep
      AWK=${pkgs.gawk}/bin/awk
      $HEADSCALE routes enable -r $($HEADSCALE routes list | $GREP homefree | $GREP "10.0.0.0" | $AWK '{ print $1 }')
    '';
  };

  homefree.service-config = if config.homefree.services.headscale.enable == true then [
    {
      label = "headscale";
      name = "VPN";
      project-name = "Headscale";
      systemd-service-name = "headscale";
      admin = {
        urlPathOverride = "/web";
      };
      reverse-proxy = {
        enable = true;
        ## @TODO: Use "vpn" as default
        subdomains = [ "headscale" "vpn" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 8087;
        public = config.homefree.services.headscale.public;
        extraCaddyConfig = ''
          reverse_proxy /web* http://10.0.0.1:3009
        '';
      };
      backup = {
        paths = [
          "/var/lib/headscale"
        ];
      };
    }
  ] else [];
}
