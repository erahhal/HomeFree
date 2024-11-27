{ config, ... }:
{
  services.headscale = {
    enable = config.homefree.services.headscale.enable;
    port = 8087;
    address = "10.0.0.1";
    settings = {
      dns = {
        base_domain = config.homefree.system.domain;
      };
    };
  };

  homefree.proxied-hosts = if config.homefree.services.headscale.enable == true then [
    {
      label = "headscale";
      subdomains = [ "headscale" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 8087;
      public = config.homefree.services.headscale.public;
    }
  ] else [];
}
