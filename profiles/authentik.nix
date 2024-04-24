{ config, inputs, pkgs, ... }:
{
  services.authentik = {
    enable = true;
    # The environmentFile needs to be on the target host!
    # Best use something like sops-nix or agenix to manage it
    environmentFile = "/run/secrets/authentik/authentik-env";
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

  sops.secrets."authentik/authentik-env" = {
    owner = "homefree";
    path = "/run/secrets/authentik/authentik-env";
    restartUnits = [ "authentik.service" ];
  };
}
