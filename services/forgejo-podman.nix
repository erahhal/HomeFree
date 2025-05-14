{ config, pkgs, ... }:
let
  version = "10.0.0";
  containerDataPath = "/var/lib/forgejo";
  port = 3201;
  ssh-port = 3022;

  preStart = ''
    mkdir -p ${containerDataPath}
  '';
in
{
  environment.systemPackages = [
    ## Installs "gitea" executable
    pkgs.forgejo
  ];

  virtualisation.oci-containers.containers = if config.homefree.services.forgejo.enable == true then {
    forgejo = {
      image = "codeberg.org/forgejo/forgejo:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString port}"
        "0.0.0.0:${toString ssh-port}:${toString ssh-port}"
      ];

      volumes = [
        "${containerDataPath}:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;

        ## app.ini server config
        FORGEJO__server__HTTP_PORT = toString port;
        FORGEJO__server__DOMAIN = "git.${config.homefree.system.domain}";
        FORGEJO__server__MINIMUM_KEY_SIZE_CHECK = "false";
        FORGEJO__server__START_SSH_SERVER = "true";
        ## Container internal port
        FORGEJO__server__SSH_LISTEN_PORT = toString ssh-port;
        ## External port
        FORGEJO__server__SSH_PORT = toString ssh-port;
        FORGEJO__server__ROOT_URL = "https://git.${config.homefree.system.domain}";

        ## app.ini service config
        FORGEJO__service__DISABLE_REGISTRATION = if config.homefree.services.forgejo.disable-registration == true then "true" else "false";

        ## app.ini migrations config
        FORGEJO__migrations__ALLOWED_DOMAINS = "*";
        FORGEJO__migrations__ALLOW_LOCALNETWORKS = "true";
        FORGEJO__migrations__SKIP_TLS_VERIFY = "true";

        ## app.ini actions config
        FORGEJO__actions__ENABLED = "true";
        FORGEJO__actions__DEFAULT_ACTIONS_URL = "github";

        ## app.ini mailer config
        # FORGEJO__mailer__ENABLED = "true";
        # FORGEJO__mailer__SMTP_ADDR = "mail.example.com";
        # FORGEJO__mailer__FROM = "noreply@${srv.DOMAIN}";
        # FORGEJO__mailer__USER = "noreply@${srv.DOMAIN}";

        ## Database config
        # FORGEJO__database__DB_TYPE = "postgres";
        # FORGEJO__database__HOST = "db:5432";
        # FORGEJO__database__NAME = "forgejo";
        # FORGEJO__database__USER = "forgejo";
        # FORGEJO__database__PASSWD = "forgejo";
      };
    };
  } else {};

  systemd.services.podman-forgejo = {
    after = [ "dns-ready.service" ];
    requires = [ "dns-ready.service" ];
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "forgejo-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.forgejo.enable == true then [
    {
      label = "forgejo";
      name = "Git";
      project-name = "Forgejo";
      systemd-service-names = [
        "podman-forgejo"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "git" "forgejo" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        public = config.homefree.services.forgejo.public;
      };
      backup = {
        paths = [
          containerDataPath
        ];
      };
    }
  ] else [];
}

