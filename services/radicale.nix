{ config, pkgs, ... }:
{
  services.radicale = {
    enable =  config.homefree.services.radicale.enable;
    settings = {
      server.hosts = [ "10.0.0.1:5232" ];

      # auth = {
      #   type = "http_x_remote_user";
      # };

      # auth = {
      #   type = "htpasswd";
      #   htpasswd_filename = "/var/lib/radicale/htpasswd";
      #   # hash function used for passwords. May be `plain` if you don't want to hash the passwords
      #   htpasswd_encryption = "bcrypt";
      # };
    };
  };

  homefree.proxied-hosts = if config.homefree.services.radicale.enable == true then [
    {
      label = "radicale";
      subdomains = [ "radicale" "dav" "webdav" "caldav" "carddav" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 5232;
      public = config.homefree.services.radicale.public;
      # basic-auth = true;
    }
  ] else [];
}
