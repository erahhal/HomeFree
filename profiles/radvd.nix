{ config, ... }:
let
  lan-interface = config.homefree.network.lan-interface;
in
{
  services.radvd = {
    enable = true;
    config = ''
      interface ${lan-interface}
      {
          AdvSendAdvert on;
          MinRtrAdvInterval 3;
          MaxRtrAdvInterval 10;
          AdvDefaultPreference low;
          AdvHomeAgentFlag off;
          prefix ::/64
          {
              AdvOnLink on;
              AdvAutonomous on;
              AdvRouterAddr off;
              AdvPreferredLifetime 120;
              AdvValidLifetime 300;
          };
          # Next line has the IPv6 address of a DNS server:
          RDNSS 2001:4860:4860::8888
          {
              AdvRDNSSLifetime 30;
          };
      };
    '';
  };
}

