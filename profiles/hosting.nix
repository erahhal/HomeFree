{ config, pkgs, ... }:
let
  hostConfig = ''
    respond "Hello, world! I am being accessed from {scheme}."
  '';
in
{
  imports = [
    ../apps/radicale.nix
  ];

  services.caddy = {
    enable = true;

    ## reload config while running instead of restarting. true by default.
    enableReload = true;

    ## With both http and https set, caddy won't redirect http to https
    ## REMOVE THIS IN PROD
    virtualHosts."http://localhost, https://localhost" = {
      # Nix config mangles the log name, so set it manually
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-localhost.log
      '';
      extraConfig = hostConfig;
    };

    virtualHosts."http://radicale.homefree.lan" = {
      logFormat = ''
        output file ${config.services.caddy.logDir}/access-radicale.log
      '';
      extraConfig = ''
        reverse_proxy :5232
      '';
    };
  };
}
