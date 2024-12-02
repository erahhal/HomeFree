{ config, pkgs, ... }:
let
  cfg = config.homefree;
  search-domains = [ cfg.system.domain cfg.system.localDomain ] ++ cfg.system.additionalDomains;
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
      dns = {
        ## Must be different from server domain
        base_domain = "homefree.vpn";
        search_domains = search-domains;
        nameservers.global = [ "10.0.0.1" ];
      };
      derp = {
        server = {
          enabled = true;
          stun_listen_addr = "0.0.0.0:3478";
        };
        ## Disable default DERP pointing at tailscale corporate servers
        urls = [ ];
        paths = [
          "/etc/headscale/derp.yaml"
        ];
      };
    };
  };

  environment.etc = {
    "headscale/derp.yaml".text = ''
      regions:
        900:
          regionid: 900
          regioncode: custom
          regionname: Homefree
          nodes:
            - name: 900a
              regionid: 900
              hostname: headscale.${cfg.system.domain}
              stunport: 3478
              stunonly: false
              derpport: 0
    '';
  };

  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale/key";
    authKeyParameters = {
      preauthorized = true;
      baseURL = "https://headscale.${config.homefree.system.domain}";
    };
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-routes=10.0.0.0/24,100.64.0.0/24"
      # "--advertise-exit-node"
      # "--exit-node-allow-lan-access"
      # "--operator ${config.homefree.system.adminUsername}"
      # "--ssh"
    ];
    extraSetFlags = [
      "--advertise-routes=10.0.0.0/24"
      # "--advertise-exit-node"
      # "--exit-node-allow-lan-access"
      # "--operator ${config.homefree.system.adminUsername}"
      # "--ssh"
    ];
  };

  sops.secrets = {
    "tailscale/key" = {
      format = "yaml";
      sopsFile = ../secrets/tailscale.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/tailscale/key";
      restartUnits = [ "tailscale.service" ];
    };
  };

  # homefree.proxied-hosts = if config.homefree.services.headscale.enable == true then [
  #   {
  #     label = "headscale";
  #     subdomains = [ "headscale" ];
  #     http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
  #     https-domains = [ config.homefree.system.domain ];
  #     port = 8087;
  #     public = config.homefree.services.headscale.public;
  #   }
  # ] else [];
}
