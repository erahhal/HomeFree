{ config, pkgs, ... }:
{
  services.immich = {
    enable = true;
    port = 3013;
    host = "10.0.0.1";
    environment.IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
    settings = {
      server = {
        ## @TODO: Have a selection between different photo apps, and
        ##        the default gets "photos" subdomain?
        externalDomain = "https://photos.${config.homefree.system.domain}";
      };
    };
  };

  ## Enable VA-API support
  users.users.immich.extraGroups = [ "video" "render" ];

  environment.systemPackages = [
    pkgs.immich-cli
    pkgs.immich-go
  ];

  homefree.service-config = if config.homefree.services.immich.enable == true then [
    {
      label = "immich";
      name = "Photos";
      project-name = "Immich";
      systemd-service-name = "immic-server";
      reverse-proxy = {
        enable = true;
        subdomains = [ "photos" "immich" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = config.services.immich.port;
        public = config.homefree.services.immich.public;
      };
      backup = {
        paths = [
          config.services.immich.mediaLocation
        ];
        postgres-databases = [
          "immich"
        ];
      };
    }
  ] else [];
}
