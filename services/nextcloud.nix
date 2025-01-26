{ config, lib, ... }:
let
  host = "nextcloud.${config.homefree.system.domain}";
  countryCode = config.homefree.system.countryCode;
  phoneRegion = if countryCode != null then (lib.toUpper countryCode) else null;
in
{
  environment.etc."nextcloud-admin-pass".text = "PWD";
  services.nextcloud = {
    enable = config.homefree.services.nextcloud.enable;
    # package = pkgs.nextcloud28;
    hostName = "localhost";
    ## Can't be changed, so admin username changing for homefree won't sync
    ## Default: root
    ## @TODO: Sync accounts with Authentik
    config = {
      adminuser = config.homefree.system.adminUsername;
      adminpassFile = config.homefree.services.nextcloud.secrets.admin-password;
      ## To change the DB type:
      ## 1. Export all relevant data
      ## 2. Delete or move /var/lib/nextcloud/config/config.php
      ## 3. Delete or move /var/lib/nextcloud/data
      ## 4. Change database settings here.
      ## 5. Rebuild nix config
      ## 6. Might have to manually restart nextcloud-setup service
      ##
      ## NOTE: files to import with nextcloud-occ need to be visible to nextcloud user, e.g.
      ##       cp deck.json /tmp/deck.json
      ##       chmod 777 /tmp/deck.json
      ##       nextcloud-occ deck:import /tmp/deck.json
      ##       rm /tmp/deck.json
      dbtype  = "pgsql";
    };
    database.createLocally = true;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks deck;
    };
    extraAppsEnable = true;

    configureRedis = true;
    settings = let
      prot = "https";
      dir = "";
    in {
      ## Settings needed to run in subdir on nginx
      overwriteprotocol = prot;
      overwritehost = host;
      overwritewebroot = dir;
      overwrite.cli.url = "${prot}://${host}${dir}/";

      ## For nextcloud android app login
      csrf.optout = [
        "/Nextcloud-android/"
      ];

      ## To get rid of security warning on admin page
      trusted_proxies = [
        "10.0.0.1/24"
      ];

      ## To get rid of js map warning on admin page
      trusted_domains = [
        host
      ];

      ## Use phone numbers without a country code
      default_phone_region = phoneRegion;

      ## Start maintenance processes at 2am
      maintenance_window_start = 2;

      htaccess.RewriteBase = dir;
    };
    phpOptions = {
      "opcache.interned_strings_buffer" = "32";
    };
    secretFile = config.homefree.services.nextcloud.secrets.secret-file;
  };

  systemd.services.nextcloud-config = {
    after = [ "phpfpm-nextcloud.service" ];
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
    };
    # script = builtins.readFile ../scripts/tune_router_performance.sh;
    script = ''
      OCC=${config.services.nextcloud.occ}/bin/nextcloud-occ

      ## Enabling the log reader results in the following system error:
      ## "Failed to get an iterator for log entries: Logreader application only supports "file" log_type"
      $OCC app:disable logreader

      ## migrate data
      $OCC maintenance:repair --include-expensive
    '';
  };

  ## Nextcloud starts nginx
  ## Setup to be at /nextcloud/ path rather than root
  services.nginx.virtualHosts."localhost" = {
    listen = [ { addr = "10.0.0.1"; port = 3010; }];
    locations = {
      "^~ /.well-known" = lib.mkForce {
        priority = 210;
        extraConfig = ''
          absolute_redirect off;
          location ~ ^/\\.well-known/host-meta(?:\\.json)?$ {
            return 301 /public.php?service=host-meta-json;
          }
          location = /.well-known/carddav {
            return 301 /remote.php/dav/;
          }
          location = /.well-known/caldav {
            return 301 /remote.php/dav/;
          }
          location ~ ^/\\.well-known/(?!acme-challenge|pki-validation) {
            return 301 /index.php$request_uri;
          }
          location = /.well-known/webfinger {
            return 301 /index.php/.well-known/webfinger;
          }
          try_files $uri $uri/ =404;
        '';
      };
      "/nextcloud/" = {
        priority = 9999;
        extraConfig = ''
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-NginX-Proxy true;
          proxy_set_header X-Forwarded-Proto http;
          proxy_pass http://${host}:3010/; # tailing / is important!
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
          proxy_redirect off;
        '';
      };
    };
  };

  homefree.service-config = if config.homefree.services.nextcloud.enable == true then [
    {
      label = "nextcloud";
      name = "Nextcloud";
      project-name = "Nextcloud";
      systemd-service-names = [
        "phpfpm-nextcloud"
        "postgresql"
        "redis-nextcloud"
        "nginx"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "nextcloud" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 3010;
        subdir = "/nextcloud/";
        public = config.homefree.services.nextcloud.public;
      };
      backup = {
        paths = [
          "/var/lib/nextcloud/data"
        ];
        postgres-databases = [
          "nextcloud"
        ];
      };
    }
  ] else [];
}
