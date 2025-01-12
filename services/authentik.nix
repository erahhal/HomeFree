{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openldap
  ];

  services.authentik = {
    enable = config.homefree.services.authentik.enable;
    # Deployed SOPS file
    environmentFile = config.homefree.services.authentik.secrets.environment;
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
    environmentFile = config.homefree.services.authentik.secrets.ldap-environment;
  };

  networking.firewall.allowedTCPPorts = [
    # 3389    # LDAP
    9000   # Web GUI
  ];

  homefree.service-config = if config.homefree.services.authentik.enable == true then [
    {
      label = "authentik";
      name = "Single Sign On";
      project-name = "Authentik";
      systemd-service-name = "authentik";
      reverse-proxy = {
        enable = true;
        subdomains = [ "auth" "authentik" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 9000;
        public = config.homefree.services.authentik.public;
      };
      backup = {
        paths = [
          "/var/lib/authentik"
        ];
        postgres-databases = [
          "authentik"
        ];
      };
    }
  ] else [];

  # # Set the authentik postgresql password
  # systemd.services.postgresql.postStart = let
  #   password_file_path = config.homefree.services.authentik.secrets.postgres-password;
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
