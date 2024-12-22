{ config, ... }:
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

  homefree.service-config = if config.homefree.services.radicale.enable == true then [
    {
      label = "radicale";
      reverse-proxy = {
        enable = true;
        subdomains = [ "radicale" "dav" "webdav" "caldav" "carddav" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 5232;
        public = config.homefree.services.radicale.public;
        # basic-auth = true;
      };
      backup = {
        paths = [
          "/var/lib/radicale"
        ];
      };
    }
  ] else [];
}
