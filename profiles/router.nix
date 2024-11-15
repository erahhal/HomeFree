{ config, homefree-inputs, pkgs, ... }:

let
  # @TODO: How to determine interface names?
  wan-interface = config.homefree.network.wan-interface;
  lan-interface = config.homefree.network.lan-interface;
  vlan-wan-id = 100;
  vlan-lan-id = 200;
  vlan-iot-id = 201;
  vlan-guest-id = 202;
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
    ## @TODO: Base on config for lan gateway
    nameservers = [ "10.1.1.1" ];

    # resolvconf = {
    # };

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
        # useDHCP = true;
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

    ## @TODO: Evaluate this
    # nat.enable = false;

    ## @TODO: Evaluate this
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
  # DHCP/DNS
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
    nssmdns4 = true;
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
