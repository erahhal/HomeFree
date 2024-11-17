
{ ... }:
{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";   # "sqlite", "mysql", "postgresql"
    ## @TODO: Setup proper backup
    backupDir = "/var/backup/vaultwarden";
    config = {
      ROCKET_ADDRESS = "10.0.0.1";
      ROCKET_PORT = 8222;
    };
  };
}
