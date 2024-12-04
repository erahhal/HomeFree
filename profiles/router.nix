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

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${wan-interface}.accept_ra" = 2;
    "net.ipv6.conf.${wan-interface}.autoconf" = 1;
    "net.ipv6.conf.${lan-interface}.accept_ra" = 2;
    "net.ipv6.conf.${lan-interface}.autoconf" = 1;
  };

  ## @TODO: Is this overlapping/conflicting with "interfaces" settings?
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
        ipv6Prefixes = [
          {
            Prefix = "::/64";
          }
        ];
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

    ## Use explicit firewall rules
    firewall.enable = false;

    ## ipv6 reference:
    ## https://superuser.com/questions/1617415/how-to-use-ipv6-internet-addresses-on-linux-with-systemd-networkd
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
            ## http is needed for headscale relaying
            tcp dport { http, https } ct state new accept;

            ## Allow wireguard connections
            udp dport { ${toString wireguard-port} } ct state new accept;

            ## Headscale connections
            udp dport { 41641 } ct state new accept;

            ## Allow Headscale DERP connections
            udp dport { ${toString config.homefree.services.headscale.stun-port} } ct state new accept;
            tcp dport { ${toString config.homefree.services.headscale.stun-port} } ct state new accept;

            ## Allow for ipv6 route advertisements
            icmpv6 type { echo-request, echo-reply, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert, nd-redirect, ind-neighbor-solicit, ind-neighbor-advert, router-renumbering, mld-listener-query, mld-listener-report, mld-listener-done, mld-listener-reduction, mld2-listener-report } accept;
            meta l4proto ipv6-icmp accept comment "Accept ICMPv6"
            meta l4proto icmp accept comment "Accept ICMP"
            ip protocol igmp accept comment "Accept IGMP"

            # DHCPv6
            ip6 saddr fe80::/10 ip6 daddr fe80::/10 udp sport 547 udp dport 546 accept

            # DHCP client traffic (for WAN interface to get IP address from modem)
            iifname "${wan-interface}" udp sport 67 udp dport 68 accept comment "Allow DHCP from WAN"

            iifname { "lo" } accept comment "Allow localhost to access the router"
            iifname { "${lan-interface}" } accept comment "Allow local network to access the router"
            iifname { "wg0" } accept comment "Allow wireguard network to access the router"
            iifname { "tailscale0" } accept comment "Allow wireguard network to access the router"
            iifname { "podman0" } accept comment "Allow podman network to access the router"

            iifname "${wan-interface}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${wan-interface}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            ## Logging is interesting but fills up dmesg. @TODO: log to another file, with reverse IP lookup and geoip
            # iifname "${wan-interface}" counter log prefix "WAN_DROP: " drop comment "Drop all other unsolicited traffic from wan"
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

            ## Headscale-WAN
            iifname { "tailscale0" } oifname { "${wan-interface}" } accept comment "Allow trusted wireguard to WAN"
            iifname { "${wan-interface}" } oifname { "tailscale0" } ct state established, related accept comment "Allow established back to wireguard"

            ## Headscale-LAN
            iifname { "tailscale0" } oifname { "${lan-interface}" } accept comment "Allow trusted wireguard to LAN"
            iifname { "${lan-interface}" } oifname { "tailscale0" } ct state established, related accept comment "Allow established back to wireguard"
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
            ## This handles tailscale0, wg0 and the lan interface
            oifname "${wan-interface}" masquerade
          }
        }
      '';
    };
  };

  #-----------------------------------------------------------------------------------------------------
  # Performance Tuning
  #-----------------------------------------------------------------------------------------------------

  ## @TODO: This was cargo-culted. Evaluate it for efficacy and correctness.
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
  ## Disabled as Unbound + Adguard is used instead
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
