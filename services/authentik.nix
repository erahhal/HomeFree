{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openldap
  ];

  services.authentik = {
    enable = config.homefree.services.authentik.enable;
    # Deployed SOPS file
    environmentFile = "/run/secrets/authentik/authentik-env";
    ## @TODO: make these configurable from module
    settings = {
      email = {
        host = "smtp.homefree.host";
        port = 587;
        username = "authentik@homefree.host";
        use_tls = true;
        use_ssl = false;
        from = "authentik@homefree.host";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };

  services.authentik-ldap = {
    enable = true;
    # Deployed SOPS file
    environmentFile = "/run/secrets/authentik/authentik-ldap-env";
  };

  networking.firewall.allowedTCPPorts = [
    # 3389    # LDAP
    9000   # Web GUI
  ];

  sops.secrets = {
    "authentik/authentik-env" = {
      format = "yaml";
      # @TODO: Move secrets to this folder
      sopsFile = ../secrets/authentik.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/authentik/authentik-env";
      restartUnits = [ "authentik.service" ];
    };
    "authentik/authentik-ldap-env" = {
      format = "yaml";
      # @TODO: Move secrets to this folder
      sopsFile = ../secrets/authentik.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/authentik/authentik-ldap-env";
      restartUnits = [ "authentik-ldap.service" ];
    };
    "authentik/postgres-password" = {
      format = "yaml";
      # @TODO: Move secrets to this folder
      sopsFile = ../secrets/authentik.yaml;
    };
  };

  homefree.service-config = if config.homefree.services.authentik.enable == true then [
    {
      label = "auth";
      reverse-proxy = {
        enable = true;
        subdomains = [ "authentik" "auth" ];
        http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
        https-domains = [ config.homefree.system.domain ];
        port = 9000;
        public = config.homefree.services.authentik.public;
      };
      backup = {
        postgres-databases = [
          "authentik"
        ];
      };
    }
  ] else [];

  # # Set the authentik postgresql password
  # systemd.services.postgresql.postStart = let
  #   password_file_path = config.sops.secrets."authentik/postgres-password".path;
  # in ''
  #   $PSQL -tA <<'EOF'
  #     DO $$
  #     DECLARE password TEXT;
  #     BEGIN
  #       password := trim(both from replace(pg_read_file('${password_file_path}'), E'\n', '''));
  #       EXECUTE format('ALTER ROLE authentik WITH PASSWORD '''%s''';', password);
  #     END $$;
  #   EOF
  # '';
}
