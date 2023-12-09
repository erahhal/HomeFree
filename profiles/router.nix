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

    # Define VLANS
    vlans = {
      wan = {
        id = vlan-wan-id;
        interface = wan-interface;
      };
      lan = {
        id = vlan-lan-id;
        interface = lan-interface;
      };
      iot = {
        id = vlan-iot-id;
        interface = lan-interface;
      };
      guest = {
        id = vlan-guest-id;
        interface = lan-interface;
      };
    };

    interfaces = {
      # Don't request DHCP on the physical interfaces
      ${wan-interface} = {
        # useDHCP = false;
      };
      ${lan-interface} = {
        useDHCP = false;
      };

      # Handle the VLANs
      wan = {
        useDHCP = false;
      };
      lan = {
        ipv4.addresses = [{
          address = "10.1.1.1";
          prefixLength = 24;
        }];
      };
      iot = {
        ipv4.addresses = [{
          address = "10.2.1.1";
          prefixLength = 24;
        }];
      };
      guest = {
        ipv4.addresses = [{
          address = "10.3.1.1";
          prefixLength = 24;
        }];
      };
    };

    #-----------------------------------------------------------------------------------------------------
    # Firewall
    #-----------------------------------------------------------------------------------------------------

    nat.enable = false;
    firewall.enable = false;

    ## @TODO: Look into nftables Nix DSL: https://github.com/chayleaf/notnft
    ##        https://www.reddit.com/r/NixOS/comments/14copvu/notnft_write_nftables_rules_in_nix/
    nftables = {
      enable = false;
      ruleset = ''
        table inet filter {
          # enable flow offloading for better throughput
          flowtable f {
            hook ingress priority 0;
            devices = { wan, lan };
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

            # Allow returning traffic from wan and drop everthing else
            iifname "wan" ct state { established, related } counter accept
            iifname "wan" drop
          }

          chain forward {
            type filter hook forward priority filter; policy drop;

            # enable flow offloading for better throughput
            ip protocol { tcp, udp } flow offload @f

            # Allow trusted network WAN access
            iifname {
                    "lan",
            } oifname {
                    "wan",
            } counter accept comment "Allow trusted LAN to WAN"

            # Allow established WAN to return
            iifname {
                    "wan",
            } oifname {
                    "lan",
            } ct state established,related counter accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority filter; policy accept;
          }

          # Setup NAT masquerading on the wan interface
          chain postrouting {
            type nat hook postrouting priority filter; policy accept;
            oifname "wan" masquerade
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
    script = builtins.readFile ../scripts/tune_router_performance.sh;
  };

  #-----------------------------------------------------------------------------------------------------
  # DHCP
  #-----------------------------------------------------------------------------------------------------

  # See: https://nixos.wiki/wiki/Systemd-resolved
  ## Needed for WAN adapter
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };

  # @TODO: Look at Unbound instead
  #   https://github.com/MayNiklas/nixos-adblock-unbound

  services.dnsmasq = {
    enable = true;

    settings = {
      ## @TODO
      ## @WARNING - changes to this do not clear out old entries from /etc/dnsmasq-conf.conf
      server = dns-servers;
      interface = [
        "${lan-interface}.${builtins.toString vlan-lan-id}"
        "${lan-interface}.${builtins.toString vlan-iot-id}"
        "${lan-interface}.${builtins.toString vlan-guest-id}"
      ];
      dhcp-range = [
        "lan,10.1.1.100,10.1.1.254,255.255.255.0,8h"
        "iot,10.2.1.100,10.2.1.254,255.255.255.0,8h"
        "guest,10.3.1.100,10.3.1.254,255.255.255.0,8h"
      ];
    };
  };

  #-----------------------------------------------------------------------------------------------------
  # DNS
  #-----------------------------------------------------------------------------------------------------

  ## @TODO - Setup Unbound
  ## See: https://blog.josefsson.org/2015/10/26/combining-dnsmasq-and-unbound/

  #-----------------------------------------------------------------------------------------------------
  # Service Discovery
  #-----------------------------------------------------------------------------------------------------

  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      "lan"
      "iot"
      "guest"
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
