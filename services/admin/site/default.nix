{ config, pkgs, ... }:
let
  homefree-admin = pkgs.callPackage ./package.nix { };
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
      name = "HomeFree Admin";
      project-name = "HomeFree Admin";
      systemd-service-name = "caddy";
      reverse-proxy = {
        enable = true;
        subdomains = [ "admin" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        static-path = "${pkgs.homefree-admin}/lib/node_modules/homefree-admin";
        ## @TODO: Don't allow this to be public until locked down
        # public = config.homefree.admin-page.public;
        public = false;
      };
    }
  ];
}
