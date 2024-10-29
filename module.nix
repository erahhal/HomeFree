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

      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "America/Los_Angeles";
        description = "Timezone for the system";
      };

      defaultLocale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
        description = "Default locale for the system";
      };

      searchDomainsLocal = lib.mkOption {
        type = lib.types.listOf lib.types.str;
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

    ddclient = lib.mkOption {
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
  };

  config = {
  };
}
