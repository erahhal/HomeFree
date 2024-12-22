{ config, ... }:
{
  services.gitea = {
    enable = config.homefree.services.gitea.enable;
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
        ROOT_URL = "https://git.${config.homefree.system.domain}";
      };
      migrations = {
        ALLOWED_DOMAINS = "*";
        ALLOW_LOCALNETWORKS = true;
        SKIP_TLS_VERIFY = true;
      };
      # service.DISABLE_REGISTRATION = true;
    };
  };

  homefree.service-config = if config.homefree.services.gitea.enable == true then [
    {
      label = "gitea";
      reverse-proxy = {
        enable = true;
        subdomains = [ "git" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 3001;
        public = config.homefree.services.gitea.public;
      };
      backup = {
        paths = [
          "/var/lib/gitea"
        ];
      };
    }
  ] else [];
}

