{ config, pkgs, ... }:
let
  homefree-admin = pkgs.callPackage  ../site/admin { };
in
{
  ## add homefree admin page as a package
  nixpkgs.overlays = [
    (final: prev: {
      homefree-admin = homefree-admin;
    })
  ];

  homefree.service-config = [
    {
      label = "admin";
      reverse-proxy = {
        enable = true;
        subdomains = [ "admin" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        static-path = "${pkgs.homefree-admin}/lib/node_modules/homefree-admin";
        public = config.homefree.admin-page.public;
      };
    }
  ];
}
