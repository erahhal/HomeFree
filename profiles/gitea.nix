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
        HTTP_PORT = 3001;
        DOMAIN = "git.${config.homefree.system.domain}";
        MINIMUM_KEY_SIZE_CHECK = false;
        START_SSH_SERVER = true;
        SSH_PORT = 3022;
      };
    };
  };
}

