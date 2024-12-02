{ config, lib, ... }:
let
  host = "nextcloud.${config.homefree.system.domain}";
in
{
  environment.etc."nextcloud-admin-pass".text = "PWD";
  services.nextcloud = {
    enable = config.homefree.services.nextcloud.enable;
    # package = pkgs.nextcloud28;
    hostName = "localhost";
    ## Can't be changed, so admin username changing for homefree won't sync
    ## Default: root
    ## @TODO: Sync up accounts
    config.adminuser = config.homefree.system.adminUsername;
    config.adminpassFile = "/run/secrets/nextcloud/admin-password";
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks deck;
    };
    extraAppsEnable = true;
    ## Also needs to be enabled in config.php
    ## https://docs.nextcloud.com/server/14/admin_manual/configuration_server/caching_configuration.html
    caching.redis = true;
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
      "csrf.optout" = [
        "/Nextcloud-android/"
      ];
      htaccess.RewriteBase = dir;

      redis = {
        host = "/run/redis/redis.sock";
        port = 0;
        dbindex = 0;
        ## Contained in secretFile
        # password = "secret";
        timeout = 1.5;
      };
    };
    secretFile = "/run/secrets/nextcloud/secret-file";
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
            return 301 /nextcloud/public.php?service=host-meta-json;
          }
          location = /.well-known/carddav {
            return 301 /nextcloud/remote.php/dav/;
          }
          location = /.well-known/caldav {
            return 301 /nextcloud/remote.php/dav/;
          }
          location ~ ^/\\.well-known/(?!acme-challenge|pki-validation) {
            return 301 /nextcloud/index.php$request_uri;
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

  sops.secrets = {
    "nextcloud/admin-password" = {
      format = "yaml";
      sopsFile = ../secrets/nextcloud.yaml;

      owner = "nextcloud";
      path = "/run/secrets/nextcloud/admin-password";
      restartUnits = [ "nextcloud.service" ];
    };
    "nextcloud/secret-file" = {
      format = "yaml";
      sopsFile = ../secrets/nextcloud.yaml;

      owner = "nextcloud";
      path = "/run/secrets/nextcloud/secret-file";
      restartUnits = [ "nextcloud.service" ];
    };
  };


  homefree.proxied-hosts = if config.homefree.services.nextcloud.enable == true then [
    {
      label = "nextcloud";
      subdomains = [ "nextcloud" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 3010;
      subdir = "/nextcloud/";
      public = config.homefree.services.nextcloud.public;
    }
  ] else [];
}
