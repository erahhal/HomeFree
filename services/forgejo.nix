{ config, ... }:
let
  port = 3201;
  ssh-port = 3023;
in
{
  services.forgejo = {
    enable = config.homefree.services.gitea.enable;
    database = {
      ## @TODO: move to postgresql
      type = "sqlite3";
    };
    lfs.enable = true;
    settings = {
      server = {
        HTTP_PORT = port;
        DOMAIN = "forgejo.${config.homefree.system.domain}";
        MINIMUM_KEY_SIZE_CHECK = false;
        START_SSH_SERVER = true;
        SSH_PORT = ssh-port;
        ROOT_URL = "https://forgejo.${config.homefree.system.domain}";
      };
      service = {
        DISABLE_REGISTRATION = config.homefree.services.forgejo.disable-registration;
      };
      migrations = {
        ALLOWED_DOMAINS = "*";
        ALLOW_LOCALNETWORKS = true;
        SKIP_TLS_VERIFY = true;
      };
      actions =  {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };
      # mailer = {
      #   ENABLED = true;
      #   SMTP_ADDR = "mail.example.com";
      #   FROM = "noreply@${srv.DOMAIN}";
      #   USER = "noreply@${srv.DOMAIN}";
      # };
    };
    # mailerPasswordFile = config.age.secrets.forgejo-mailer-password.path;
  };

  homefree.service-config = if config.homefree.services.forgejo.enable == true then [
    {
      label = "forgejo";
      name = "Git";
      project-name = "Forgejo";
      systemd-service-names = [
        "forgejo"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "forgejo" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.gitea.public;
      };
      backup = {
        paths = [
          "/var/lib/forgejo"
        ];
      };
    }
  ] else [];
}

