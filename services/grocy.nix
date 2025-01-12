{ config, ... }:
{
  services.grocy = {
    # enable = config.homefree.services.grocy.enable;
    ## Currently, nginx port 80 conflicts with caddy
    enable = false;
    hostName = "grocy.${config.homefree.system.domain}";
    nginx.enableSSL = false;
  };

  homefree.service-config = if config.homefree.services.grocy.enable == true then [
    {
      label = "grocy";
      name = "Grocy";
      project-name = "Grocy";
      systemd-service-name = "grocy";
      reverse-proxy = {
        enable = true;
        subdomains = [ "grocy" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 7746;
        public = config.homefree.services.grocy.public;
      };
      backup = {
        paths = [
          "/var/lib/grocy"
        ];
      };
    }
  ] else [];
}

