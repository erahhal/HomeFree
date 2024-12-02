{ config, pkgs, ... }:
let
  linkwarden = pkgs.callPackage ../provisional/linkwarden/package.nix {};
in
{
  nixpkgs.overlays = with pkgs; [( final: prev: { linkwarden = linkwarden; }) ];
  imports = [
    ../provisional/linkwarden/overlays.nix
    ../provisional/linkwarden/module.nix
  ];

  services.linkwarden = {
    enable = config.homefree.services.linkwarden.enable;
    enableRegistration = true;
    host = "10.0.0.1";
    port = 3005;
    openFirewall = true;
    secretsFile = "/run/secrets/linkwarden/env";
    database = {
      user = "linkwarden";
    };
  };

  sops.secrets = {
    "linkwarden/env" = {
      format = "yaml";
      sopsFile = ../secrets/linkwarden.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/linkwarden/env";
      restartUnits = [ "linkwarden.service" ];
    };
  };

  homefree.proxied-hosts = if config.homefree.services.linkwarden.enable == true then [
    {
      label = "linkwarden";
      subdomains = [ "linkwarden" ];
      http-domains = [ "homefree.${config.homefree.system.localDomain}" ];
      https-domains = [ config.homefree.system.domain ];
      port = 3005;
      public = config.homefree.services.linkwarden.public;
    }
  ] else [];
}
