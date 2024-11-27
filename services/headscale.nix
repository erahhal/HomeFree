{ config, ... }:
{
  services.headscale = {
    enable = true;
    port = 8087;
    address = "10.0.0.1";
  };

  homefree.proxied-hosts = if config.homefree.services.headscale.enable == true then [
    {
      label = "headscale";
      subdomains = [ "headscale" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 3007;
      public = config.homefree.services.headscale.public;
    }
  ] else [];
}
