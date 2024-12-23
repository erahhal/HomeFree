{ config, pkgs, lib, ... }:
let
  cfg = config.services.ddclient-multi;
  boolToStr = bool: if bool then "yes" else "no";
  dataDir = "/var/lib/ddclient";
  StateDirectory = builtins.baseNameOf dataDir;
  RuntimeDirectory = StateDirectory;

  configFile' = pkgs.writeText "ddclient.conf" (''
    # This file can be used as a template for configFile or is automatically generated by Nix options.
    cache=${dataDir}/ddclient.cache
    foreground=YES
    quiet=${boolToStr cfg.quiet}
    verbose=${boolToStr cfg.verbose}
    ${lib.optionalString (cfg.use != "") "use=${cfg.use}"}
    ${lib.optionalString (cfg.use == "" && cfg.usev4 != "") "usev4=${cfg.usev4}"}
    ${lib.optionalString (cfg.use == "" && cfg.usev6 != "") "usev6=${cfg.usev6}"}

    ${cfg.extraConfig}
  '' + lib.concatMapStrings (zoneCfg: ''

    login=${zoneCfg.username}
    password=${if zoneCfg.protocol == "nsupdate" then "/run/${RuntimeDirectory}/${zoneCfg.zone}/ddclient.key" else "@${zoneCfg.zone}_password_placeholder@"}
    protocol=${zoneCfg.protocol}
    ssl=${boolToStr zoneCfg.ssl}
    wildcard=YES
    ${lib.optionalString (zoneCfg.script != "") "script=${zoneCfg.script}"}
    ${lib.optionalString (zoneCfg.server != "") "server=${zoneCfg.server}"}
    ${lib.optionalString (zoneCfg.extraConfig != "") zoneCfg.extraConfig}
    ${lib.optionalString (zoneCfg.zone != "")   "zone=${zoneCfg.zone}"}
    ${lib.concatStringsSep "," zoneCfg.domains}
  '') (lib.filter (zone: zone.disable == false) cfg.zones));
  configFile = if (cfg.configFile != null) then cfg.configFile else configFile';

  preStart = ''
    install --mode=600 --owner=$USER ${configFile} /run/${RuntimeDirectory}/ddclient.conf
    ${lib.optionalString (cfg.configFile == null) (lib.concatMapStrings (zoneCfg:
    if (zoneCfg.protocol == "nsupdate") then ''
      install --mode=600 --owner=$USER ${zoneCfg.passwordFile} /run/${RuntimeDirectory}/${zoneCfg.zone}/ddclient.key
    '' else if (zoneCfg.passwordFile != null) then ''
      "${pkgs.replace-secret}/bin/replace-secret" "@${zoneCfg.zone}_password_placeholder@" "${zoneCfg.passwordFile}" "/run/${RuntimeDirectory}/ddclient.conf"
    '' else ''
      sed -i '/^password=@${zoneCfg.zone}_password_placeholder@$/d' /run/${RuntimeDirectory}/ddclient.conf
    '') cfg.zones)}
  '';

in

with lib;

{

  imports = [
    (mkRemovedOptionModule [ "services" "ddclient-multi" "homeDir" ] "")
    (mkRemovedOptionModule [ "services" "ddclient-multi" "password" ] "Use services.ddclient-multi.passwordFile instead.")
    (mkRemovedOptionModule [ "services" "ddclient-multi" "ipv6" ] "")
  ];

  ###### interface

  options = {
    services.ddclient-multi = with lib.types; {
      enable = mkOption {
        default = false;
        type = bool;
        description = ''
          Whether to synchronise your machine's IP address with a dynamic DNS provider (e.g. dyndns.org).
        '';
      };

      package = mkOption {
        type = package;
        default = pkgs.ddclient;
        defaultText = lib.literalExpression "pkgs.ddclient";
        description = ''
          The ddclient executable package run by the service.
        '';
      };

      interval = mkOption {
        default = "10min";
        type = str;
        description = ''
          The interval at which to run the check and update.
          See {command}`man 7 systemd.time` for the format.
        '';
      };

      configFile = mkOption {
        default = null;
        type = nullOr path;
        description = ''
          Path to configuration file.
          When set this overrides the generated configuration from module options.
        '';
        example = "/root/nixos/secrets/ddclient.conf";
      };

      quiet = mkOption {
        default = false;
        type = bool;
        description = ''
          Print no messages for unnecessary updates.
        '';
      };

      use = lib.mkOption {
        default = "";
        type = str;
        description = ''
          Method to determine the IP address to send to the dynamic DNS provider.
        '';
      };

      usev4 = lib.mkOption {
        default = "webv4, webv4=checkip.dyndns.com/, webv4-skip='Current IP Address: '";
        type = str;
        description = ''
          Method to determine the IPv4 address to send to the dynamic DNS provider. Only used if `use` is not set.
        '';
      };

      usev6 = lib.mkOption {
        default = "webv6, webv6=checkipv6.dyndns.com/, webv6-skip='Current IP Address: '";
        type = str;
        description = ''
          Method to determine the IPv6 address to send to the dynamic DNS provider. Only used if `use` is not set.
        '';
      };

      verbose = mkOption {
        default = false;
        type = bool;
        description = ''
          Print verbose information.
        '';
      };

      extraConfig = mkOption {
        default = "";
        type = lines;
        description = ''
          Extra configuration. Contents will be added verbatim to the configuration file.

          ::: {.note}
          `daemon` should not be added here because it does not work great with the systemd-timer approach the service uses.
          :::
        '';
      };

      zones = mkOption {
        default = [];
        description = ''
          Config per zone.
        '';
        type = with lib.types; listOf (submodule {
          options = rec {
            disable = mkOption {
              default = false;
              type = bool;
              description = ''
                Disable zone
              '';
            };

            domains = mkOption {
              default = [ "" ];
              type = listOf str;
              description = ''
                Domain name(s) to synchronize.
              '';
            };

            username = mkOption {
              # For `nsupdate` username contains the path to the nsupdate executable
              default = lib.optionalString (protocol == "nsupdate") "${pkgs.bind.dnsutils}/bin/nsupdate";
              defaultText = "";
              type = str;
              description = ''
                User name.
              '';
            };

            passwordFile = mkOption {
              default = null;
              type = nullOr str;
              description = ''
                A file containing the password or a TSIG key in named format when using the nsupdate protocol.
              '';
            };

            protocol = mkOption {
              default = "dyndns2";
              type = str;
              description = ''
                Protocol to use with dynamic DNS provider (see https://ddclient.net/protocols.html ).
              '';
            };

            server = mkOption {
              default = "";
              type = str;
              description = ''
                Server address.
              '';
            };

            ssl = mkOption {
              default = true;
              type = bool;
              description = ''
                Whether to use SSL/TLS to connect to dynamic DNS provider.
              '';
            };

            script = mkOption {
              default = "";
              type = str;
              description = ''
                script as required by some providers.
              '';
            };

            zone = mkOption {
              default = "";
              type = str;
              description = ''
                zone as required by some providers.
              '';
            };

            extraConfig = mkOption {
              default = "";
              type = lines;
              description = ''
                Extra configuration for zone. Contents will be added verbatim to the zone-specific config.
              '';
            };
          };
        });
      };
    };
  };

  ###### implementation

  config = mkIf config.services.ddclient-multi.enable {
    systemd.services.ddclient-multi = {
      description = "Dynamic DNS Client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartTriggers = optional (cfg.configFile != null) cfg.configFile;
      path = lib.optional (lib.hasPrefix "if," cfg.use) pkgs.iproute2;

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectoryMode = "0700";
        inherit RuntimeDirectory;
        inherit StateDirectory;
        Type = "oneshot";
        ExecStartPre = [ "!${pkgs.writeShellScript "ddclient-prestart" preStart}" ];
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '${lib.getExe cfg.package} -file /run/${RuntimeDirectory}/ddclient.conf 2>&1 | ${pkgs.coreutils-full}/bin/tee >(${pkgs.gnugrep}/bin/grep -q "422" && exit 0); exit ''\${pipestatus[0]}'
        '';
      };
    };

    systemd.timers.ddclient-multi = {
      description = "Run ddclient";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.interval;
        OnUnitInactiveSec = cfg.interval;
      };
    };
  };
}
