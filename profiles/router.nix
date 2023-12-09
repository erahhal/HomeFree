{ pkgs, ... }:

let
  # @TODO: How to determine interface names?
  # wan-interface = "ens5";
  wan-interface = "ens3";
  # lan-interface = "ens6";
  lan-interface = "ens5";
  vlan-wan-id = 100;
  vlan-lan-id = 200;
  vlan-iot-id = 201;
  vlan-guest-id = 202;
  # lan-interface = "ens3";
  dns-servers = [ "1.1.1.1" "1.0.0.1" ];
in
{

  # REFERENCES:
  # https://github.com/chayleaf/nixos-router
  #   https://github.com/chayleaf/dotfiles/blob/master/system/hosts/router/default.nix
  # https://francis.begyn.be/blog/nixos-home-router
  # https://discourse.nixos.org/t/do-you-use-nixos-on-your-router-firewall/18998
  # https://homenetworkguy.com/how-to/set-up-a-fully-functioning-home-network-using-opnsense/

  #-----------------------------------------------------------------------------------------------------
  # IP Forwarding
  #-----------------------------------------------------------------------------------------------------

  boot.kernel.sysctl = {
    # if you use ipv4, this is all you need
    "net.ipv4.conf.all.forwarding" = true;

    # If you want to use it for ipv6
    "net.ipv6.conf.all.forwarding" = true;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${wan-interface}.accept_ra" = 2;
    "net.ipv6.conf.${wan-interface}.autoconf" = 1;
  };

  networking = {
    #-----------------------------------------------------------------------------------------------------
    # Interface config
    #-----------------------------------------------------------------------------------------------------

    useDHCP = false;
    nameservers = dns-servers;

    ## Define VLANS
    ## https://www.breakds.org/post/vlan-configuration-by-examples/
    # vlans = {
    #   wan = {
    #     id = vlan-wan-id;
    #     interface = wan-interface;
    #   };
    #   lan = {
    #     id = vlan-lan-id;
    #     interface = lan-interface;
    #   };
    #   iot = {
    #     id = vlan-iot-id;
    #     interface = lan-interface;
    #   };
    #   guest = {
    #     id = vlan-guest-id;
    #     interface = lan-interface;
    #   };
    # };

    interfaces = {
      # Don't request DHCP on the physical interfaces
      ${wan-interface} = {
        # useDHCP = false;
      };
      ${lan-interface} = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "10.1.1.1";
          prefixLength = 24;
        }];
      };

      # Handle the VLANs
      # wan = {
      #   useDHCP = false;
      # };
      # lan = {
      #   ipv4.addresses = [{
      #     address = "10.1.1.1";
      #     prefixLength = 24;
      #   }];
      # };
      # iot = {
      #   ipv4.addresses = [{
      #     address = "10.2.1.1";
      #     prefixLength = 24;
      #   }];
      # };
      # guest = {
      #   ipv4.addresses = [{
      #     address = "10.3.1.1";
      #     prefixLength = 24;
      #   }];
      # };
    };

    #-----------------------------------------------------------------------------------------------------
    # Firewall
    #-----------------------------------------------------------------------------------------------------

    nat.enable = false;
    firewall.enable = false;

    ## @TODO: Look into nftables Nix DSL: https://github.com/chayleaf/notnft
    ##        https://www.reddit.com/r/NixOS/comments/14copvu/notnft_write_nftables_rules_in_nix/
    nftables = {
      enable = true;
      ruleset = ''
        flush ruleset

        # table ip filter {
        #   # allow all packets sent by the firewall machine itself
        #   chain output {
        #     type filter hook output priority 100; policy accept;
        #   }
        #
        #   # allow LAN to firewall, disallow WAN to firewall
        #   chain input {
        #     type filter hook input priority 0; policy accept;
        #     iifname "${lan-interface}" accept
        #     iifname "${wan-interface}" drop
        #   }
        #
        #   # allow packets from LAN to WAN, and WAN to LAN if LAN initiated the connection
        #   chain forward {
        #     type filter hook forward priority 0; policy drop;
        #     iifname "${lan-interface}" oifname "${wan-interface}" accept
        #     iifname "${wan-interface}" oifname "${lan-interface}" ct state related,established accept
        #   }
        # }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority 0; policy accept;
          }

          # for all packets to WAN, after routing, replace source address with primary IP of WAN interface
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "${wan-interface}" masquerade
          }
        }
      '';
    };
  };

  #-----------------------------------------------------------------------------------------------------
  # Performance Tuning
  #-----------------------------------------------------------------------------------------------------

  systemd.services.tune-router-performance = {
    wantedBy = [ "multi-user.target" ];
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
    };
    # script = builtins.readFile ../scripts/tune_router_performance.sh;
    script = ''
      GREP=${pkgs.gnugrep}/bin/grep
      AWK=${pkgs.gawk}/bin/awk
      # SMP - Symmetric MultiProcessing
      # RPS - Receive Packet Steering

      smp1=3
      rps1=2
      smp2=3
      rps2=2

      ens3_irq=$($GREP ens3 /proc/interrupts | $AWK '{ print $1+0 }')

      # set balancer for enp1s0
      echo $smp1 > /proc/irq/$ens3_irq/smp_affinity

      # set rps for ens3
      echo $rps1 > /sys/class/net/ens3/queues/rx-0/rps_cpus

      ens5_irq=$($GREP ens5 /proc/interrupts | $AWK '{ print $1+0 }')

      # set balancer for enp2s0
      # echo $smp2 > /proc/irq/$ens5_irq/smp_affinity

      # set rps for ens5
      echo $rps2 > /sys/class/net/ens5/queues/rx-0/rps_cpus
    '';
  };

  #-----------------------------------------------------------------------------------------------------
  # DHCP
  #-----------------------------------------------------------------------------------------------------

  # See: https://nixos.wiki/wiki/Systemd-resolved
  ## Disabled as it conflicts with dnsmasq
  services.resolved = {
    enable = false;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

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
      server = dns-servers;

      ## Which interfaces to bind to
      interface = [
        # "${lan-interface}.${builtins.toString vlan-lan-id}"
        # "${lan-interface}.${builtins.toString vlan-iot-id}"
        # "${lan-interface}.${builtins.toString vlan-guest-id}"
        lan-interface
      ];

      ## IP ranges to hand out
      dhcp-range = [
        # "lan,10.1.1.100,10.1.1.254,255.255.255.0,8h"
        # "iot,10.2.1.100,10.2.1.254,255.255.255.0,8h"
        # "guest,10.3.1.100,10.3.1.254,255.255.255.0,8h"
        "${lan-interface},10.1.1.100,10.1.1.254,255.255.255.0,8h"
      ];

      ## Disable DNS
      port = 0;

      ## Additional DHCP options
      dhcp-option = [
        "option6:dns-server,[::]"  # @TODO: point this at Unbound when ipv6 is setup
        "option:dns-server,10.1.1.1"
      ];

      cache-size = 500;
    };
  };

  #-----------------------------------------------------------------------------------------------------
  # DNS
  #-----------------------------------------------------------------------------------------------------

  ## @TODO - Setup Unbound
  ## See: https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

  services.unbound = {
    enable = true;

    user = "root";

    resolveLocalQueries = true;

    settings = {
      server = {
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
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
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

  #-----------------------------------------------------------------------------------------------------
  # Service Discovery
  #-----------------------------------------------------------------------------------------------------

  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      # "lan"
      # "iot"
      # "guest"
      lan-interface
    ];

    # network locator e.g. scanners and printers
    nssmdns = true;
  };

  #-----------------------------------------------------------------------------------------------------
  # Packages
  #-----------------------------------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    ethtool             # manage NIC settings (offload, NIC feeatures, ...)
    tcpdump             # view network traffic
    conntrack-tools     # view network connection states
  ];
}
