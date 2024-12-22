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
    secretsFile = config.homefree.services.linkwarden.secrets.environment;
    database = {
      user = "linkwarden";
    };
  };

  homefree.service-config = if config.homefree.services.linkwarden.enable == true then [
    {
      label = "linkwarden";
      reverse-proxy = {
        enable = true;
        subdomains = [ "links" "linkwarden" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "10.0.0.1";
        port = 3005;
        public = config.homefree.services.linkwarden.public;
      };
      backup = {
        postgres-databases = [
          "linkwarden"
        ];
      };
    }
  ] else [];
}
