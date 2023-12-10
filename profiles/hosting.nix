{ pkgs, ... }:

{
  imports = [
    ../apps/radicale.nix
  ];

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    virtualHosts."localhost" = {
      extraConfig = ''
        respond "Hello, world!"
      '';
    };

    virtualHosts."http://radicale.homefree.lan" = {
      extraConfig = ''
        reverse_proxy :5232
      '';
    };
  };
}
