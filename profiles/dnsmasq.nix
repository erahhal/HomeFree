{ config, lib, pkgs, ... }:
let
  lan-interface = config.homefree.network.lan-interface;
  wan-interface = config.homefree.network.wan-interface;
in
{
  services.dnsmasq = {
    enable = true;

    settings = {
      ## @TODO
      ## @WARNING - changes to this do not clear out old entries from /etc/dnsmasq-conf.conf

      ## Only DHCP server on network
      dhcp-authoritative = true;

      ## Don't listen to anything on wan interface
      except-interface = wan-interface;

      ## Don't send bogus requests to internet
      bogus-priv = true;

      ## Enable Router Advertising for ipv6
      enable-ra = true;

      ## Ipv6
      ## ra-param = "${lan-interface},0,0";  ## This disables router-advertisements
      ra-param = "${lan-interface},10,300";

      ## DNS servers to pass to clients
      ## @TODO: Make this based on configured gateway IP
      server = [ "10.0.0.1" ];

      ## Which interfaces to bind to
      interface = [
        # "${lan-interface}.${builtins.toString vlan-lan-id}"
        # "${lan-interface}.${builtins.toString vlan-iot-id}"
        # "${lan-interface}.${builtins.toString vlan-guest-id}"
        lan-interface
      ];

      ## IP ranges to hand out
      dhcp-range = [
        # "lan,10.0.0.100,10.0.0.254,255.255.255.0,8h"
        # "iot,10.2.1.100,10.2.1.254,255.255.255.0,8h"
        # "guest,10.3.1.100,10.3.1.254,255.255.255.0,8h"
        "tag:${lan-interface},::1,constructor:${lan-interface},ra-names,slaac,12h"    #ipv6
        # "::,constructor:${lan-interface},ra-stateless"                              # ipv6
        "${lan-interface},10.0.0.100,10.0.0.254,255.255.255.0,8h"                     # ipv4
      ];

      ## Disable DNS, since Unbound is handling DNS
      port = 0;

      cache-size = 500;

      ## Additional DHCP options
      dhcp-option = [
        "option6:dns-server,[::]"  # @TODO: point this at Unbound when ipv6 is setup
        "option:dns-server,10.0.0.1"
      ];

      dhcp-host = lib.map (ip-config:
        "${ip-config.mac-address},${ip-config.hostname},${ip-config.ip},${config.homefree.network.static-ip-expiration}")
        config.homefree.network.static-ips;
    };
  };

  ## dhcpd6 is obsolete
  # services.dhcpd6 = {};

  # services.kea.dhcp6 = {
  #   enable = true;
  #   settings = {
  #     interfaces-config = {
  #       interfaces = [
  #         lan-interface
  #       ];
  #     };
  #     lease-database = {
  #       name = "/var/lib/kea/dhcp6.leases";
  #       persist = true;
  #       type = "memfile";
  #     };
  #     preferred-lifetime = 3000;
  #     rebind-timer = 2000;
  #     renew-timer = 1000;
  #     subnet6 = [
  #       {
  #         id = 1;
  #         subnet = "2001:db8:1::/64";
  #         pools = [
  #           {
  #             pool = "2001:db8:1::1-2001:db8:1::ffff";
  #           }
  #         ];
  #       }
  #     ];
  #     valid-lifetime = 4000;
  #   };
  # };
}

