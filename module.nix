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
        default = "lan";
        description = ''
          local lan domain for internal devices and services.

          Default is "lan". Don't choose "local", as this can conflict with Multicast DNS (mDNS) services,
          such as Apple's Bonjour/Zeroconf. "local" is also a reserved TLD and some tools and browsers
          might trigger cert warnings.

          Other common localdomains you can use:
          "localdomain"
          "home"
          "private"
          "internal"
        '';
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

      forgejo = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Forgejo git service";
        };

        disable-registration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Disable user registration";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
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

        media-path = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Location to save recording";
        };

        enable-backup-media = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to backup records";
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

        disable-registration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Disable user registration";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      grocy = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Homebox inventory management service";
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
          default = true;
          description = "Open to public on WAN port";
        };

        stun-port = lib.mkOption {
          type = lib.types.int;
          description = "DERP STUN relay port";
          ## Now using Unifi in a docker container to block STUN port conflict
          default = 3478;
          ## Non-standard port to avoid conflict with Unifi Controller STUN listener
          # default = 3578;
        };

        secrets = {
          tailscale-key = lib.mkOption {
            type = lib.types.path;
            description = "Location of Tailscale client key for server. Should not be a file included in your source repo.";
          };
          headplane-env = lib.mkOption {
            type = lib.types.path;
            description = "Location of Headplane environment var file. Contains COOKIE_SECRET, ROOT_API_KEY, OIDC_CLIENT_SECRET. Should not be a file included in your source repo.";
          };
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

      homebox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Homebox inventory management service";
        };

        disable-registration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Disable user registration";
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

      joplin = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Joplin notes service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      kanidm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "enable Kanidm";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };
      };

      lidarr = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Lidarr music management service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        media-path = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Location of music media";
        };

        downloads-path = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Location of downloads";
        };

        enable-backup-media = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to backup media";
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

      logseq = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Logseq knowledge management service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
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

      nzbget = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable NZBGet downloader";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        downloads-path = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Location of downloads";
        };

        enable-backup-media = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to backup media";
        };
      };

      ollama = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Ollama GenAI service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
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

      snipe-it = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Snipe-IT inventory management service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        secrets = {
          mysql-password = lib.mkOption {
            type = lib.types.path;
            description = "Location of Snipe-IT mysql password file. Should not be a file included in your source repo.";
          };
          env = lib.mkOption {
            type = lib.types.path;
            description = "Location of Snipe-IT env file. Contains DB_PASSWORD, which is the same as mysql-password above, and APP_KEY. Should not be a file included in your source repo.";
          };
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

      zitadel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "enable Zitadel auth service";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open to public on WAN port";
        };

        secrets = {
          env = lib.mkOption {
            type = lib.types.path;
            description = "Location of Zitadel environment var file. Contains ZITADEL_MASTERKEY. Should not be a file included in your source repo.";
          };
        };
      };
    };

    service-config = lib.mkOption {
      description = "Detailed config for services";
      type = with lib.types; listOf (submodule {
        options = {
          label = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Unique label for service";
          };

          name = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Full name of service";
          };

          icon = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to service icon";
          };

          project-name = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Official project name of application";
          };

          release-tracking = {
            type = lib.mkOption {
              type = lib.types.str;
              default = "github";
              description = "Project release service type";
            };

            project = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Project path, e.g. <owner>/<repo> for github";
            };
          };

          systemd-service-names = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Associated systemd services";
          };

          admin = {
            show = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Show in Admin UI";
            };

            urlPathOverride = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Override path of URL to service";
            };
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

            rootDomain = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Maps to root domain, i.e. no subdomain. Only one service can set this to true.";
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
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "host name or address of service to proxy";
            };

            port = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "port of service on lan network";
            };

            static-path = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "path to static files to serve. Do not set host or port if using this.";
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

            extraCaddyConfig = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "custom caddy config";
            };
          };

          backup = {
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [];
              description = "list of paths to backup";
            };

            mysql-databases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "list of mysql databases to backup";
            };

            postgres-databases = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "list of postgres databases to backup";
            };
          };
        };
      });
    };

    docker-io-auth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable docker.io auth";
      };

      username = lib.mkOption {
        type = lib.types.str;
        description = "docker.io username";
      };

      secrets = {
        password = lib.mkOption {
          type = lib.types.path;
          description = "Location of docker.io password file Should not be a file included in your source repo.";
        };
      };
    };

    admin-page = {
      public = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open to public on WAN port (not recommended)";
      };
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
        badServiceConfigs = builtins.filter (entry: (entry.reverse-proxy.host != null || entry.reverse-proxy.port != null) && entry.reverse-proxy.static-path != null) config.homefree.service-config;
        badServiceConfigLabels = builtins.map (entry: entry.label) badServiceConfigs;
        rootDomainConfigs = builtins.filter (entry: (entry.reverse-proxy.rootDomain == true)) config.homefree.service-config;
        rootDomainConfigLabels = builtins.map (entry: entry.label) rootDomainConfigs;
      in
    [
      {
        ## Make sure that two service configs don't use the same label
        assertion = lib.length duplicateLabels == 0;
        message = "Multiple homefree.service-config entries with the same label: ${lib.concatStringsSep ", " duplicateLabels}";
      }
      {
        assertion = lib.length badServiceConfigs == 0;
        message = "homefree.service-config contains entries with both a host/port and static-path config; can only specify one: ${lib.concatStringsSep ", " badServiceConfigLabels}";
      }
      {
        assertion = lib.length rootDomainConfigs <= 1;
        message = "homefree.service-config contains more than one service with rootDomain = true: ${lib.concatStringsSep ", " rootDomainConfigLabels}";
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
