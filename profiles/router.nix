{ pkgs, ... }:

let
  interface-name = "enp1s0";
  dns-ip = "<DNS IP>";
in
{

  # REFERENCES:
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
    "net.ipv6.conf.${interface-name}.accept_ra" = 2;
    "net.ipv6.conf.${interface-name}.autoconf" = 1;
  };

  networking = {
    #-----------------------------------------------------------------------------------------------------
    # Interface config
    #-----------------------------------------------------------------------------------------------------

    useDHCP = false;
    hostName = "router";
    nameserver = [ dns-ip ];

    # Define VLANS
    vlans = {
      wan = {
        id = 10;
        interface = "enp1s0";
      };
      lan = {
        id = 20;
        interface = "enp2s0";
      };
      iot = {
        id = 90;
        interface = "enp2s0";
      };
    };

    interfaces = {
      # Don't request DHCP on the physical interfaces
      enp1s0.useDHCP = false;
      enp2s0.useDHCP = false;
      enp3s0.useDHCP = false;

      # Handle the VLANs
      wan.useDHCP = false;
      lan = {
        ipv4.addresses = [{
          address = "10.1.1.1";
          prefixLength = 24;
        }];
      };
      iot = {
        ipv4.addresses = [{
          address = "10.1.90.1";
          prefixLength = 24;
        }];
      };
    };

    #-----------------------------------------------------------------------------------------------------
    # Firewall
    #-----------------------------------------------------------------------------------------------------

    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          # enable flow offloading for better throughput
          flowtable f {
            hook ingress priority 0;
            devices = { ppp0, lan };
          }

          chain output {
            type filter hook output priority 100; policy accept;
          }

          chain input {
            type filter hook input priority filter; policy drop;

            # Allow trusted networks to access the router
            iifname {
              "lan",
            } counter accept

            # Allow returning traffic from ppp0 and drop everthing else
            iifname "ppp0" ct state { established, related } counter accept
            iifname "ppp0" drop
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            # enable flow offloading for better throughput
            ip protocol { tcp, udp } flow offload @f

            # Allow trusted network WAN access
            iifname {
                    "lan",
            } oifname {
                    "ppp0",
            } counter accept comment "Allow trusted LAN to WAN"

            # Allow established WAN to return
            iifname {
                    "ppp0",
            } oifname {
                    "lan",
            } ct state established,related counter accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority filter; policy accept;
          }

          # Setup NAT masquerading on the ppp0 interface
          chain postrouting {
            type nat hook postrouting priority filter; policy accept;
            oifname "ppp0" masquerade
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
    script = ../scripts/tune_router_performance.sh;
  };

  #-----------------------------------------------------------------------------------------------------
  # DHCP
  #-----------------------------------------------------------------------------------------------------

  services.dhcpd4 = {
    enable = true;
    interfaces = [ "lan" "iot" ];
    extraConfig = ''
      option domain-name-servers 10.5.1.10, 1.1.1.1;
      option subnet-mask 255.255.255.0;

      subnet 10.1.1.0 netmask 255.255.255.0 {
        option broadcast-address 10.1.1.255;
        option routers 10.1.1.1;
        interface lan;
        range 10.1.1.128 10.1.1.254;
      }

      subnet 10.1.90.0 netmask 255.255.255.0 {
        option broadcast-address 10.1.90.255;
        option routers 10.1.90.1;
        option domain-name-servers 10.1.1.10;
        interface iot;
        range 10.1.90.128 10.1.90.254;
      }
    '';
  };

  #-----------------------------------------------------------------------------------------------------
  # Service Discovery
  #-----------------------------------------------------------------------------------------------------

  services.avahi = {
    enable = true;
    reflector = true;
    interfaces = [
      "lan"
      "iot"
    ];
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
