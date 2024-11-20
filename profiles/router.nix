{ config, homefree-inputs, pkgs, ... }:

let
  # @TODO: How to determine interface names?
  wan-interface = config.homefree.network.wan-interface;
  lan-interface = config.homefree.network.lan-interface;
  wireguard-port = config.homefree.wireguard.listenPort;
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
    # enable ipv4 forwarding
    "net.ipv4.conf.all.forwarding" = true;

    # enable ipv6 forwarding
    "net.ipv6.conf.all.forwarding" = true;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-3/configuration.nix#L46[]
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${wan-interface}.accept_ra" = 2;
    "net.ipv6.conf.${wan-interface}.autoconf" = 1;
  };

  systemd.network = {
    networks = {
      "01-${lan-interface}" = {
        name = lan-interface;
        networkConfig = {
          Description = "LAN link";
          Address = "10.0.0.1/24";
          LinkLocalAddressing = "yes";
          IPv6AcceptRA = "no";
          # Announce a prefix here and act as a router.
          IPv6SendRA = "yes";
          # Use a DHCPv6-PD delegated prefix (DHCPv6PrefixDelegation.SubnetId)
          # from the pool and assigns one /64 to this network.
          DHCPPrefixDelegation = "yes";
        };
        ipv6SendRAConfig = {
          # Currently dnsmasq manages DNS servers.
          EmitDNS = "no";
          EmitDomains = "no";
        };
      };
    };
  };

  networking = {
    #-----------------------------------------------------------------------------------------------------
    # Interface config
    #-----------------------------------------------------------------------------------------------------

    useDHCP = false;
    ## @TODO: Base on config for lan gateway
    nameservers = [ "10.0.0.1" ];

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
      ${wan-interface} = {
        useDHCP = true;
      };
      ${lan-interface} = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "10.0.0.1";
          prefixLength = 24;
        }];
        # ipv6.addresses = [{
        #   address = "2001:DB8::";
        #   prefixLength = 64;
        # }];
      };

      # Handle the VLANs
      # wan = {
      #   useDHCP = false;
      # };
      # lan = {
      #   ipv4.addresses = [{
      #     address = "10.0.0.1";
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

        ## "inet" indicates both ipv4 and ipv6
        table inet filter {
          ## allow all packets sent by the firewall machine itself
          chain output {
            type filter hook output priority 100; policy accept;
          }

          ## allow LAN to firewall, disallow WAN to firewall
          chain input {
            type filter hook input priority 0; policy drop;

            ## Allow for web traffic
            tcp dport { https } ct state new accept;

            ## Allow wireguard connections
            udp dport { ${toString wireguard-port} } ct state new accept;

            ## Allow for ipv6 route advertisements
            icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert, mld-listener-query } accept;

            iifname { "lo" } accept comment "Allow localhost to access the router"
            iifname { "${lan-interface}" } accept comment "Allow local network to access the router"
            iifname { "wg0" } accept comment "Allow wireguard network to access the router"

            iifname "${wan-interface}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${wan-interface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "${wan-interface}" counter drop comment "Drop all other unsolicited traffic from wan"
          }

          ## allow packets from LAN to WAN, and WAN to LAN if LAN initiated the connection
          chain forward {
            type filter hook forward priority 0; policy drop;

            ## LAN-WAN
            iifname { "${lan-interface}" } oifname { "${wan-interface}" } accept comment "Allow trusted LAN to WAN"
            iifname { "${wan-interface}" } oifname { "${lan-interface}" } ct state established, related accept comment "Allow established back to LANs"

            ## @TODO: Confirm which, if any, of these are needed.

            ## Wireguard-WAN
            iifname { "wg0" } oifname { "${wan-interface}" } accept comment "Allow trusted wireguard to WAN"
            iifname { "${wan-interface}" } oifname { "wg0" } ct state established, related accept comment "Allow established back to wireguard"

            ## Wireguard-LAN
            iifname { "wg0" } oifname { "${lan-interface}" } accept comment "Allow trusted wireguard to LAN"
            iifname { "${lan-interface}" } oifname { "wg0" } ct state established, related accept comment "Allow established back to wireguard"
          }
        }

        ## only need "ip" (ipv4), not "inet" (ipv4+ipv6) as it breaks ipv6 on clients. NAT is not needed for ipv6.
        table ip nat {
          chain prerouting {
            ## Lower priority number indicates higher priority
            type nat hook prerouting priority 0; policy accept;
          }

          # for all packets to WAN, after routing, replace source address with primary IP of WAN interface
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            ## This handles both wg0 and the lan interface
            oifname "${wan-interface}" masquerade
          }
        }
      '';
    };
  };

  # systemd.services.block-wan-traffic = {
  #   wantedBy = [ "multi-user.target" ];
  #   enable = true;
  #   serviceConfig = {
  #     User = "root";
  #     Group = "root";
  #   };
  #   script = ''
  #     IPTABLES=${pkgs.iptables}/bin/iptables
  #
  #     $IPTABLES -A INPUT -i ${wan-interface} -p tcp -m tcp -m multiport --dports 80,443 -j ACCEPT
  #     $IPTABLES -A INPUT -i ${wan-interface} -p tcp -m tcp -m multiport --dports ${toString config.homefree.wireguard.listenPort} -j ACCEPT
  #     $IPTABLES -A INPUT -i ${wan-interface} -m conntrack -j ACCEPT  --ctstate RELATED,ESTABLISHED
  #     $IPTABLES -A INPUT -i ${wan-interface} -j DROP
  #     # $IPTABLES -A OUTPUT -o ${wan-interface} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  #     # $IPTABLES -A OUTPUT -o ${wan-interface} -j DROP
  #     # $IPTABLES -A FORWARD -i ${wan-interface} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  #     # $IPTABLES -A FORWARD -i ${wan-interface} -j DROP
  #   '';
  # };

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

      wan_irq=$($GREP ${wan-interface} /proc/interrupts | $AWK '{ print $1+0 }')

      # set balancer for enp1s0
      echo $smp1 > /proc/irq/$wan_irq/smp_affinity

      # set rps for wan interface
      echo $rps1 > /sys/class/net/${wan-interface}/queues/rx-0/rps_cpus

      lan_irq=$($GREP ${lan-interface} /proc/interrupts | $AWK '{ print $1+0 }')

      # set balancer for enp2s0
      # echo $smp2 > /proc/irq/$lan_irq/smp_affinity

      # set rps for lan interface
      echo $rps2 > /sys/class/net/${lan-interface}/queues/rx-0/rps_cpus
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
