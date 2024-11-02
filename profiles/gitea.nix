{ config, ... }:
{
  services.gitea = {
    enable = true;
    database = {
      ## @TODO: move to postgresql
      type = "sqlite3";
    };
    settings = {
      server = {
        HTTP_PORT = 3000;
        DOMAIN = "git.${config.homefree.system.domain}";
      };
    };
  };
}

