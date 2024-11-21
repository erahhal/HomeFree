{ config, lib, pkgs, ... }:
let
  lan-interface = config.homefree.network.lan-interface;
  wan-interface = config.homefree.network.wan-interface;
  localDomain = config.homefree.system.localDomain;
  dhcp-script = pkgs.writeShellScript "dhcp-script" ''
    # $1 = action (add, del, old)
    # $2 = MAC address
    # $3 = IP address
    # $4 = hostname

    if [ "$1" = "add" ]; then
      ${pkgs.dnsutils}/bin/nsupdate -l <<EOF
      server 127.0.0.1
      zone ${localDomain}
      update delete $4.${localDomain} A
      update add $4.${localDomain} 3600 A $3
      send
    EOF
      ${pkgs.dnsutils}/bin/nsupdate -l <<EOF
      server 127.0.0.1
      update delete $4 A
      update add $4 3600 A $3
      send
    EOF
    fi
  '';
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

      ## Never forward addresses in the non-routed address spaces (don't send bogus requests to internet)
      bogus-priv = true;

      ## Enable Router Advertising for ipv6
      enable-ra = true;

      ## Ipv6
      # ra-param = "${lan-interface},0,0";  ## This disables router-advertisements
      ## Send out advertisements every 10 seconds, and make sure they are valid for 7200 seconds (2h)
       ra-param = "${lan-interface},10,7200";

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
        ## "constructor" gets the ipv6 range from the WAN interface since it's dynamic can't be hard coded here.
        ## "ra-names" includes the hostname in router advertisement messages for local name resolution
        ## "slaac" specifies how addresses are allocated. In this case, it tells clients to create
        ## their own address by using the advertised prefix + MAC address, and then the clients send
        ## a message to validate that it's not a duplicate with another address.
        "tag:${lan-interface},::1,constructor:${lan-interface},ra-names,slaac,12h"    # ipv6
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

      dhcp-script = "${dhcp-script}";
    };
  };

  ## dhcpd6 is obsolete
  # services.dhcpd6 = {};
}

