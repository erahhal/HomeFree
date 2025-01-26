{ config, ... }:
{
  services.homebox = {
    enable = config.homefree.services.homebox.enable;
    settings = {
      HBOX_OPTIONS_ALLOW_REGISTRATION = toString (!config.homefree.services.homebox.disable-registration);
      HBOX_WEB_PORT = "7745";
    };
  };

  homefree.service-config = if config.homefree.services.homebox.enable == true then [
    {
      label = "homebox";
      name = "Homebox";
      project-name = "Homebox";
      systemd-service-names = [
        "homebox"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "homebox" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 7745;
        public = config.homefree.services.homebox.public;
      };
      backup = {
        paths = [
          "/var/lib/homebox"
        ];
      };
    }
  ] else [];
}

