## @TODO: Look at the following for a VM test setup
## https://github.com/nix-community/disko/blob/master/module.nix

{ lib, ... }:

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

      adminUsername = lib.mkOption {
        type = lib.types.str;
        default = "homefree";
        description = "Username for the system admin";
      };

      adminHashedPassword = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Hashed password for the system admin";
      };

      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "SSH authorized keys for the system admin";
      };
    };

    network = {
      ## @TODO: Detect during setup
      wan-interface = lib.mkOption {
        type = lib.types.str;
        default = "ens3";
        description = "External interface to the internet";
      };

      ## @TODO: Detect during setup
      lan-interface = lib.mkOption {
        type = lib.types.str;
        default = "ens5";
        description = "Internal interface to the local network";
      };
    };

    ddclient = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable dynamic DNS client";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "10m";
        description = "Interval for dynamic DNS client";
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

      zone = lib.mkOption {
        type = lib.types.str;
        default = "homefree.host";
        description = "Zone for dynamic DNS client";
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "*" "www" "dev" ];
        description = "Domains for dynamic DNS client";
      };

      use = lib.mkOption {
        type = lib.types.str;
        default = "web, web=ipinfo.io/ip";
        description = "Use format for dynamic DNS client";
      };
    };

    wireguard = {
      peers = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
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
      };
    };
  };

  config = {
  };
}
