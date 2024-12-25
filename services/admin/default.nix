{ config, pkgs, ... }:
let
  homefree-admin = pkgs.callPackage  ./site { };
in
{
  ## add homefree admin page as a package
  nixpkgs.overlays = [
    (final: prev: {
      homefree-admin = homefree-admin;
    })
  ];

  ## @TODO: Defaults to port 4000. Create a parameter
  ##        that can be passed in to deno command line

  ## @TODO: Make a proper package so that Deno doesn't
  ##        pull down deps at runtime
  systemd.services.admin-api = {
    description = "Admin API Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      WorkingDirectory = "${./api}";
      ExecStart = "${pkgs.deno}/bin/deno task start";
      Restart = "always";
    };
  };

  homefree.service-config = [
    {
      label = "admin";
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
    {
      label = "api";
      reverse-proxy = {
        enable = true;
        subdomains = [ "api" ];
        http-domains = [ "homefree.lan" config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        host = "localhost";
        ## @TODO: Defaults to port 4000. Create a parameter
        ##        that can be passed in to deno command line
        port = 4000;
        ## @TODO: Don't allow this to be public until locked down
        # public = config.homefree.admin-page.public;
        public = false;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    deno
  ];
}
