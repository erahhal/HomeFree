## @TODO: Look at the following for a VM test setup
## https://github.com/nix-community/disko/blob/master/module.nix

{ config, options, lib, pkgs, extendModules, ... }:

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

      ## @TODO: Detect or have user enter during setup
      timeZone = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Timezone for the system in tz database format.
          See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

          example: America/Los_Angeles
        '';
      };

      countryCode = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Country code in ISO-3166-1 two-letter code format.
          See: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements

          example: US
        '';
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
              type = lib.types.path;
              description = "Path to password file";
            };
          };
        });
      };
    };

    services = {
      adguard = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "enable AdGuard Home Ad Blocking";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      authentik = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "enable Authentik";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        secrets = {
          environment = lib.mkOption {
            type = lib.types.path;
            description = "Location of Authentik environment variables file. Should not be a file included in your source repo.";
          };

          ldap-environment = lib.mkOption {
            type = lib.types.path;
            description = "Location of Authentik LDAP environment variables file. Should not be a file included in your source repo.";
          };
        };
      };

      baikal = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Baikal WebDAV/CalDAV/CardDAV service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      cryptpad = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Cryptpad Document service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        adminKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Public keys that have access to admin panel";
        };
      };

      frigate = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Frigate video recording service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        cameras = lib.mkOption {
          description = "list of cameras";
          type = with lib.types; listOf (submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Camera enabled";
              };

              name = lib.mkOption {
                type = lib.types.str;
                description = "Camera name";
              };

              path = lib.mkOption {
                type = lib.types.str;
                description = "URL / path to camera";
              };

              width = lib.mkOption {
                type = lib.types.int;
                default = 1920;
                description = "Width in pixels";
              };

              height = lib.mkOption {
                type = lib.types.int;
                default = 1080;
                description = "Height in pixels";
              };
            };
          });
        };
      };

      gitea = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Gitea git service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      headscale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Headscale vpn service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        stun-port = lib.mkOption {
          type = lib.types.int;
          description = "DERP STUN relay port";
          ## Non-standard port to avoid conflict with Unifi Controller STUN listener
          default = 3578;
        };

        secrets = {
          tailscale-key = lib.mkOption {
            type = lib.types.path;
            description = "Location of Tailscale client key for server. Should not be a file included in your source repo.";
          };
        };
      };

      headscale-ui = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Headscale UI service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      homeassistant = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Home Assistant Home Automation";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      immich = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Immich photo management service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      jellyfin = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Jellyfin media server";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      linkwarden = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Linkwarden bookmarks service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        secrets = {
          environment = lib.mkOption {
            type = lib.types.path;
            description = "Location of Linkwarden environment variables file. Should not be a file included in your source repo.";
          };
        };
      };

      matrix = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Matrix chat service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        admin-account = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Admin user for matrix synapse server";
        };

        secrets = {
          registration-shared-secret = lib.mkOption {
            type = lib.types.path;
            description = "Location of Matrix Synapse shared secret file. Should not be a file included in your source repo.";
          };
          admin-account-password = lib.mkOption {
            type = lib.types.path;
            description = "Location of admin account password. Should not be a file included in your source repo.";
          };
        };
      };

      nextcloud = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Nextcloud media server";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        secrets = {
          admin-password = lib.mkOption {
            type = lib.types.path;
            description = "Location of Nextcloud admin password file. Should not be a file included in your source repo.";
          };

          secret-file = lib.mkOption {
            type = lib.types.path;
            description = "Location of Nextcloud secrets file. Should not be a file included in your source repo.";
          };
        };
      };

      radicale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Radicale WebDAV/CalDAV/CardDAV service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      unifi = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Unifi controller";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      vaultwarden = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Vaultwarden Bitwarden password manager backend";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };
    };

    service-config = lib.mkOption {
      description = "Detailed config for services";
      type = with lib.types; listOf (submodule {
        options = {
          ## @TODO: ensure this is unique
          label = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Unique label for service";
          };

          reverse-proxy = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable reverse proxy for service";
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

            subdir = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "subdir at which service is served";
              default = null;
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

            basic-auth = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable basic auth headers";
            };
          };

          backup = {
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [];
              description = "list of paths to backup";
            };

            postgres-databases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "list of databases to backup";
            };
          };
        };
      });
    };

    landing-page = {
      path = lib.mkOption {
        type = lib.types.path;
        default = "${pkgs.homefree-site}/lib/node_modules/homefree-site/public";
        description = "Path to landing page";
      };
    };

    backups = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable backups";
      };

      to-path = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/backups";
        description = "Path to store backups";
      };

      extra-from-paths = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "Extra list of custom paths to backup";
      };

      backblaze = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable Backblaze backups";
        };

        bucket = lib.mkOption {
          type = lib.types.str;
          description = "Bucket name";
        };
      };

      secrets = {
        restic-password = lib.mkOption {
          type = lib.types.path;
          description = "Location of Restic password file. Should not be a file included in your source repo.";
        };

        restic-environment = lib.mkOption {
          type = lib.types.path;
          description = ''
            Location of Restic environment variables.

            If using Backblaze, put in your ID and key in here, e.g.:

            B2_ACCOUNT_ID=<id>
            B2_ACCOUNT_KEY=<key>

            Should not be a file included in your source repo.";
          '';
        };

        backblaze-id = lib.mkOption {
          type = lib.types.path;
          description = "Location of file with Backblaze ID. Should not be a file included in your source repo.";
        };

        backblaze-key = lib.mkOption {
          type = lib.types.path;
          description = "Location of file with Backblaze key. Should not be a file included in your source repo.";
        };
      };
    };
  };

  config = {
    assertions =
      let
        elemInList = x: xs: lib.foldl' (acc: el: acc || el == x) false xs;
        unique = list:
          if list == [] then []
          else let
            x = builtins.head list;
            xs = builtins.tail list;
          in
            if elemInList x xs
            then unique xs
            else [x] ++ (unique xs);

        # Returns a list of labels that have duplicates (preserving original case)
        findDuplicateLabels = service-config:
          let
            # Create a list of label+lowercase pairs to preserve original case
            labelPairs = map (entry: {
              original = entry.label;
              lower = lib.toLower entry.label;
            }) service-config;

            # Helper to count occurrences of a label
            countOccurrences = label: builtins.foldl'
              (acc: pair: if pair.lower == label then acc + 1 else acc)
              0
              labelPairs;

            # Get unique lowercase labels
            lowerLabels = unique (map (pair: pair.lower) labelPairs);

            # Filter for labels that appear multiple times
            duplicateLowerLabels = builtins.filter
              (label: countOccurrences label > 1)
              lowerLabels;

            # Get first occurrence of original case for each duplicate
            getDuplicateOriginal = lowerLabel:
              (builtins.head (builtins.filter
                (pair: pair.lower == lowerLabel)
                labelPairs)).original;
          in
            map getDuplicateOriginal duplicateLowerLabels;

        duplicateLabels = findDuplicateLabels config.homefree.service-config;
      in
    [
      {
        ## Make sure that two service configs don't use the same label
        assertion = lib.length duplicateLabels == 0;
        message = "Multiple homefree.service-config entries with the same label: ${lib.concatStringsSep ", " duplicateLabels}";
      }
    ];

    warnings =
      (if config.homefree.backups.enable == false then [
        ''
          Backups not enabled. Set:module

            homefree.backups.enable = true;
        ''
      ] else [])
    ++
      (if config.homefree.backups.to-path == options.homefree.backups.to-path.default then [
        ''
          Backups being written locally to the default path of "${config.homefree.backups.path}".
          You should backup to an off-machine location, e.g. to an NFS mounted path. To change
          the backup path:

            homefree.backups.to-path = "<backup path>";
        ''
      ] else [])
    ++
      (if config.homefree.landing-page.path == options.homefree.landing-page.path.default then [
        ''
          Landing page is set to the default Homefree project landing page.

            homefree.landing-page.path = "<path to html root>";
        ''
      ] else [])
    ;
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
