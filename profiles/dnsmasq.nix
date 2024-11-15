{ config, lib, ... }:
{
  services.dnsmasq = {
    enable = true;

    settings = {
      ## @TODO
      ## @WARNING - changes to this do not clear out old entries from /etc/dnsmasq-conf.conf

      ## Only DHCP server on network
      dhcp-authoritative = true;

      ## Enable Router Advertising for ipv6
      enable-ra = true;

      ## DNS servers to pass to clients
      ## @TODO: Make this based on configured gateway IP
      server = [ "10.1.1.1" ];

      ## Which interfaces to bind to
      interface = [
        # "${lan-interface}.${builtins.toString vlan-lan-id}"
        # "${lan-interface}.${builtins.toString vlan-iot-id}"
        # "${lan-interface}.${builtins.toString vlan-guest-id}"
        config.homefree.network.lan-interface
      ];

      ## IP ranges to hand out
      dhcp-range = [
        # "lan,10.1.1.100,10.1.1.254,255.255.255.0,8h"
        # "iot,10.2.1.100,10.2.1.254,255.255.255.0,8h"
        # "guest,10.3.1.100,10.3.1.254,255.255.255.0,8h"
        "${config.homefree.network.lan-interface},10.1.1.100,10.1.1.254,255.255.255.0,8h"
      ];

      ## Disable DNS, since Unbound is handling DNS
      port = 0;

      cache-size = 500;

      ## Additional DHCP options
      dhcp-option = [
        "option6:dns-server,[::]"  # @TODO: point this at Unbound when ipv6 is setup
        "option:dns-server,10.1.1.1"
      ];

      dhcp-host = lib.map (ip-config:
        "${ip-config.mac-address},${ip-config.hostname},${ip-config.ip},${config.homefree.network.static-ip-expiration}")
        config.homefree.network.static-ips;
    };
  };
}

