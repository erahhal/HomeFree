
{ config, ... }:
{
  services.vaultwarden = {
    enable =  config.homefree.services.vaultwarden.enable;
    dbBackend = "sqlite";   # "sqlite", "mysql", "postgresql"
    ## @TODO: Setup proper backup
    backupDir = "/var/backup/vaultwarden";
    config = {
      ROCKET_ADDRESS = "10.0.0.1";
      ROCKET_PORT = 8222;
    };
  };

  homefree.proxied-hosts = if config.homefree.services.vaultwarden.enable == true then [
    {
      label = "vaultwarden";
      subdomains = [ "vaultwarden" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 8222;
      public = config.homefree.services.vaultwarden.public;
    }
  ] else [];
}
