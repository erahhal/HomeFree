{ config, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  services.unifi = {
    enable = config.homefree.services.unifi.enable;
    openFirewall = true;
    unifiPackage = pkgs.unifi8;
    mongodbPackage = pkgs.mongodb-7_0;
  };

  homefree.service-config = if config.homefree.services.unifi.enable == true then [
    {
      label = "unifi";
      name = "Unifi Controller";
      project-name = "Unifi Controller";
      systemd-service-names = [
        "unifi"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "unifi" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 8443;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.unifi.public;
      };
      backup = {
        paths = [
          ## @TODO: how to programmatically set backup frequency? Unifi UI defaults to monthly.
          "/var/lib/unifi/data/backup"
        ];
      };
    }
  ] else [];
}

