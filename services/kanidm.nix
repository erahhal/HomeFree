## @TODO:debug
## Should be part of the UI install process
## Config admin
# docker exec -i -t kanidmd kanidmd recover-account admin
## User management admin
# docker exec -i -t kanidmd kanidmd recover-account idm_admin

## @TODO:
## Check podman logs and eradicate all security warnings (mostly due to /var/lib file perms)
## https://kanidm.github.io/kanidm/stable/security_hardening.html

## @TODO: Automate group creation
## kanidm group create homefree_users --name idm_admin
## kanidm group add-members homefree_users ${config.homefree.system.adminUsername} --name idm_admin

## @TODO: App specific (forgejo):
## kanidm system oauth2 create forgejo Git https://git.${config.homefree.system.domain}/user/login --name idm_admin
## kanidm system oauth2 add-redirect-url forgejo https://git.${config.homefree.system.domain}/user/oauth2/kanidm/callback --name idm_admin
## kanidm system oauth2 update-scope-map forgejo homefree_users email openid profile groups --name idm_admin
## kanidm system oauth2 warning-insecure-client-disable-pkce forgejo --name idm_admin
## kanidm system oauth2 show-basic-secret forgejo --name idm_admin
## gitea admin auth add-oauth \
##   --provider=openidConnect \
##   --name=kanidm \
##   --key=foregejo \
##   --secret=[from show-basic-secret above] \
##   --auto-discover-url=https://idm.${config.homefree.system.domain}/oauth2/openid/forgejo/.well-known/openid-configuration

{ config, pkgs, ... }:
let
  version = "1.4.6";
  containerDataPath = "/var/lib/kanidm";

  port = 3445;

  internal-web-port = 8443;

  ldap-port = 636;

  internal-ldap-port = 3636;

  kanidm-config = {
    #   The webserver bind address. Requires TLS certificates.
    #   If the port is set to 443 you may require the
    #   NET_BIND_SERVICE capability.
    #   Defaults to "127.0.0.1:8443"
    bindaddress = "[::]:${toString internal-web-port}";
    #
    #   The read-only ldap server bind address. Requires
    #   TLS certificates. If set to 636 you may require
    #   the NET_BIND_SERVICE capability.
    #   Defaults to "" (disabled)
    ldapbindaddress = "[::]:${toString internal-ldap-port}";

    #   HTTPS requests can be reverse proxied by a loadbalancer.
    #   To preserve the original IP of the caller, these systems
    #   will often add a header such as "Forwarded" or
    #   "X-Forwarded-For". If set to true, then this header is
    #   respected as the "authoritative" source of the IP of the
    #   connected client. If you are not using a load balancer
    #   then you should leave this value as default.
    #   Defaults to false
    trust_x_forward_for = true;

    #   The path to the kanidm database.
    db_path = "/data/kanidm.db";

    #   If you have a known filesystem, kanidm can tune the
    #   database page size to match. Valid choices are:
    #   [zfs, other]
    #   If you are unsure about this leave it as the default
    #   (other). After changing this
    #   value you must run a vacuum task.
    #   - zfs:
    #     * sets database pagesize to 64k. You must set
    #       recordsize=64k on the zfs filesystem.
    #   - other:
    #     * sets database pagesize to 4k, matching most
    #       filesystems block sizes.
    # db_fs_type = "zfs";

    #   The number of entries to store in the in-memory cache.
    #   Minimum value is 256. If unset
    #   an automatic heuristic is used to scale this.
    #   You should only adjust this value if you experience
    #   memory pressure on your system.
    # db_arc_size = 2048;

    #   TLS chain and key in pem format. Both must be present.
    #   If the server receives a SIGHUP, these files will be
    #   re-read and reloaded if their content is valid.
    tls_chain = "/data/chain.pem";
    tls_key = "/data/key.pem";

    #   The log level of the server. May be one of info, debug, trace
    #
    #   NOTE: this can be overridden by the environment variable
    #   `KANIDM_LOG_LEVEL` at runtime
    #   Defaults to "info"
    log_level = "info";

    #   The DNS domain name of the server. This is used in a
    #   number of security-critical contexts
    #   such as webauthn, so it *must* match your DNS
    #   hostname. It is used to create
    #   security principal names such as `william@idm.example.com`
    #   so that in a (future) trust configuration it is possible
    #   to have unique Security Principal Names (spns) throughout
    #   the topology.
    #
    #   ⚠️  WARNING ⚠️
    #
    #   Changing this value WILL break many types of registered
    #   credentials for accounts including but not limited to
    #   webauthn, oauth tokens, and more.
    #   If you change this value you *must* run
    #   `kanidmd domain rename` immediately after.
    domain = "idm.${config.homefree.system.domain}";

    #   The origin for webauthn. This is the url to the server,
    #   with the port included if it is non-standard (any port
    #   except 443). This must match or be a descendent of the
    #   domain name you configure above. If these two items are
    #   not consistent, the server WILL refuse to start!
    #   origin = "https://idm.example.com";
    origin = "https://idm.${config.homefree.system.domain}";

    online_backup = {
      #   The path to the output folder for online backups
      path = "/data/kanidm/backups/";
      #   The schedule to run online backups (see https://crontab.guru/)
      #   every day at 22:00 UTC (default)
      schedule = "00 22 * * *";
      #    four times a day at 3 minutes past the hour, every 6th hours
      # schedule = "03 */6 * * *"
      #   We also support non standard cron syntax, with the following format:
      #   sec  min   hour   day of month   month   day of week   year
      #   (it's very similar to the standard cron syntax, it just allows to specify the seconds
      #   at the beginning and the year at the end)
      #   Number of backups to keep (default 7)
      # versions = 7
    };
  };

  config-toml = (pkgs.formats.toml {}).generate "server.toml" kanidm-config;

  preStart = ''
    mkdir -p ${containerDataPath}

    cp ${config-toml} ${containerDataPath}/server.toml

    if [ ! -f ${containerDataPath}/chain.pem ]; then
      ${pkgs.podman}/bin/podman run --rm -i -t -v ${containerDataPath}:/data docker.io/kanidm/server:${version} kanidmd cert-generate
    fi

    chmod -R 400 ${containerDataPath}
  '';

  # ~/.config/kanidm
  user-config = ''
    uri = "https://idm.${config.homefree.system.domain}"
    verify_ca = false
  '';

  username = config.homefree.system.adminUsername;

  user-config-path = "/home/${username}/.config";

  kanidm-script = pkgs.writeShellScriptBin "kanidm" ''
    ${pkgs.podman}/bin/podman run --rm -i -t \
      -v /home/${username}/.config/kanidm:/root/.config/kanidm \
      -v /home/${username}/.cache/kanidm_tokens:/root/.cache/kanidm_tokens \
      docker.io/kanidm/tools:${version} kanidm "$@"
  '';
in
{
  environment.systemPackages = [
    kanidm-script
  ];

  system.activationScripts.kanidmUserConfig = {
    text = ''
      mkdir -p ${user-config-path}
      cat > ${user-config-path}/kanidm << 'EOF'
      ${user-config}
      EOF
      chown -R ${username}:users ${user-config-path}
      chmod 0744 ${user-config-path}
      chmod 0644 ${user-config-path}/kanidm
    '';
  };

  virtualisation.oci-containers.containers = if config.homefree.services.kanidm.enable == true then {
    kanidm = {
      image = "docker.io/kanidm/server:${version}";

      autoStart = true;

      extraOptions = [
        "--pull=always"
      ];

      ports = [
        "0.0.0.0:${toString port}:${toString internal-web-port}"
        "0.0.0.0:${toString ldap-port}:${toString internal-ldap-port}"
      ];

      volumes = [
        "${containerDataPath}:/data"
      ];

      environment = {
        TZ = config.homefree.system.timeZone;
      };
    };
  } else {};

  systemd.services.podman-kanidm = {
    serviceConfig = {
      ExecStartPre = [ "!${pkgs.writeShellScript "kanidm-prestart" preStart}" ];
    };
  };

  homefree.service-config = if config.homefree.services.kanidm.enable == true then [
    {
      label = "kanidm";
      name = "Kanidm Authentication";
      project-name = "Kanidm";
      systemd-service-names = [
        "podman-kanidm"
      ];
      reverse-proxy = {
        enable = true;
        subdomains = [ "idm" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = port;
        ssl = true;
        ssl-no-verify = true;
        public = config.homefree.services.kanidm.public;
      };
      backup = {
        paths = [
          "${containerDataPath}"
        ];
      };
    }
  ] else [];
}

