## @TODO: Look at the following for a VM test setup
## https://github.com/nix-community/disko/blob/master/module.nix

{ config, lib, extendModules, ... }:

# let
#   vmVariantWithHomefree = extendModules {
#     modules = [
#       ./lib/interactive-vm.nix
#     ];
#   };
# in
{
  options.homefree = {
    system = {
      hostName = lib.mkOption {
        type = lib.types.str;
        default = "homefree";
        description = "Hostname for the system";
      };

      ## @TODO: Detect during setup
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "America/Los_Angeles";
        description = "Timezone for the system";
      };

      ## @TODO: Detect during setup
      defaultLocale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
        description = "Default locale for the system";
      };

      localDomain = lib.mkOption {
        type = lib.types.str;
        ## @TODO: Should this be "local"?
        default = "localdomain";
        description = "local lan domain";
      };

      ## @TODO: Deduplicate this with localDomain
      ## recursive?
      searchDomainsLocal = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        ## @TODO: Should this be "local"?
        default = [ "localdomain" ];
        description = "Search domain for the system";
      };

      domain = lib.mkOption {
        type = lib.types.str;
        default = "homefree.host";
        description = "Domain for the system";
      };

      additionalDomains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional zones for the system";
      };

      adminUsername = lib.mkOption {
        type = lib.types.str;
        default = "homefree";
        description = "Username for the system admin";
      };

      adminHashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Hashed password for the system admin
          Generate with:
          mkpasswd -m sha-512
        '';
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "SSH authorized keys for the system admin";
      };
    };

    ## @TODO: Add default subnet and gateway config, e.g. 10.0.0.0/24, 10.0.0.1
    ## @TODO: This section doesn't make sense. Some network config is in "system" above
    ##        and some is in separate services, e.g. unbound and ddns
    network = {
      ## @TODO: Detect during setup
      wan-interface = lib.mkOption {
        type = lib.types.str;
        default = "ens3";
        description = "External interface to the internet";
      };

      wan-bitrate-mbps-down = lib.mkOption {
        type = lib.types.int;
        description = "WAN download bitrate in Mbit/s";
      };

      wan-bitrate-mbps-up = lib.mkOption {
        type = lib.types.int;
        description = "WAN upload bitrate in Mbit/s";
      };

      ## @TODO: Detect during setup
      lan-interface = lib.mkOption {
        type = lib.types.str;
        default = "ens5";
        description = "Internal interface to the local network";
      };

      static-ip-expiration = lib.mkOption {
        type = lib.types.str;
        default = "3d";
        description = "Expiration time of static IPs";
      };

      static-ips = lib.mkOption {
        default = [];
        description = "Static IP mappings";
        type = with lib.types; listOf (submodule {
          options = {
            mac-address = lib.mkOption {
              type = lib.types.str;
              description = "MAC address to assign IP to";
            };

            hostname = lib.mkOption {
              type = lib.types.str;
              description = "Hostname to assign to IP";
            };

            ip = lib.mkOption {
              type = lib.types.str;
              description = "IP Address";
            };
          };
        });
      };

      ## @TODO: Make type for dns override entry
      dns-overrides = lib.mkOption {
        description = "dns hostname to IP overrides";
        default = [];
        type = with lib.types; listOf (submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.str;
              description = "Hostname of override";
            };

            domain = lib.mkOption {
              type = lib.types.str;
              description = "Domain of override";
            };

            ip = lib.mkOption {
              type = lib.types.str;
              description = "IP Address";
            };
          };
        });
      };

      enable-adblock = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "enable ad blocking";
      };

      blocked-domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "list of domains to block";
      };
    };

    dynamic-dns = {
      interval = lib.mkOption {
        type = lib.types.str;
        default = "10m";
        description = "Interval for dynamic DNS client";
      };

      usev4 = lib.mkOption {
        type = lib.types.str;
        default = "webv4, webv4=ipinfo.io/ip";
        description = "Use format for obtaining ipv4 for dynamic DNS client";
      };

      usev6 = lib.mkOption {
        type = lib.types.str;
        default = "webv6, webv6=v6.ipinfo.io/ip";
        description = "Use format for obtaining ipv6 for dynamic DNS client";
      };

      zones = lib.mkOption {
        description = "Dynamic DNS Zone Config";
        default = [];
        type = with lib.types; listOf (submodule {
          options = {
            disable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "disable dynamic dns for zone";
            };

            ## @TODO: validate against network.domain and network.additionalDomains?
            zone = lib.mkOption {
              type = lib.types.str;
              default = "homefree.host";
              description = "Zone for dynamic DNS client";
            };

            protocol = lib.mkOption {
              type = lib.types.str;
              default = "hetzner";
              description = "Protocol for dynamic DNS client";
            };

            username = lib.mkOption {
              type = lib.types.str;
              default = "erahhal";
              description = "Username for dynamic DNS client";
            };

            domains = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "@" "*" "www" "dev" ];
              description = "Domains for dynamic DNS client";
            };

            passwordFile = lib.mkOption {
              type = lib.types.str;
              description = "String path to password file";
            };
          };
        });
      };
    };

    wireguard = {
      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 64210;
        description = "External listening port for clients";
      };
      peers = lib.mkOption {
        description = "List of wireguard peers";
        example = ''
          [
            # List of allowed peers.
            { # Feel free to give a meaning full name
              # Public key of the peer (not a file path).
              publicKey = "{client public key}";
              # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
              allowedIPs = [ "10.100.0.2/32" ];
            }
            { # John Doe
              publicKey = "{john doe's public key}";
              allowedIPs = [ "10.100.0.3/32" ];
            }
          ];
        '';
        type = with lib.types; listOf (submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Name of peer";
            };

            publicKey = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Public key for peer";
            };

            allowedIPs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.";
            };
          };
        });
      };
    };

    proxied-hosts = lib.mkOption {
      description = "List of hosts on lan to proxy";
      type = with lib.types; listOf (submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "label of proxy config";
          };

          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "description of proxy config";
          };

          subdomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "list of subdomains";
          };

          http-domains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "list of http domains";
          };

          https-domains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "list of https domains";
          };

          host = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.1";
            description = "host name or address of service to proxy";
          };

          port = lib.mkOption {
            type = lib.types.int;
            description = "port of service on lan network";
          };

          public = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to expose on WAN interface";
          };

          ssl = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether upstream service is using TLS";
          };

          ssl-no-verify = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to verify certificate of upstream service";
          };
        };
      });
    };
  };

  # options.virtualisation.vmVariantWithHomefree = lib.mkOption {
  #   description = ''
  #     Machine configuration to be added for the vm script available at `.system.build.vmWithHomefree`.
  #   '';
  #   inherit (vmVariantWithHomefree) type;
  #   default = { };
  #   visible = "shallow";
  # };
  #
  # config = {
  #   system.build = {
  #     testVms = lib.mkDefault config.virtualisation.vmVariantWithHomefree.system.build.vmWithHomefree;
  #   };
  # };
}
