{ config, pkgs, ... }:
let
  homefree-site = pkgs.callPackage ./site { };
in
{
  ## add homefree default site as a package
  nixpkgs.overlays = [
    (final: prev: {
      homefree-site = homefree-site;
    })
  ];

  homefree.service-config = [
    {
      label = "landing-page";
      reverse-proxy = {
        enable = true;
        rootDomain = true;
        subdomains = [ "www" "homefree" ];
        http-domains = [ config.homefree.system.localDomain ];
        https-domains = [ config.homefree.system.domain ];
        static-path = config.homefree.landing-page.path;
        public = true;
        extraCaddyConfig = ''
          # Matrix Synapse settings
          respond /.well-known/matrix/server `{"m.server": "matrix.${config.homefree.system.domain}:443"}`
          # respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.${config.homefree.system.domain}"},"m.identity_server":{"base_url":"https://identity.${config.homefree.system.domain}"}}`
          respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.${config.homefree.system.domain}"}}`
        '';
      };
    }
  ];
}
