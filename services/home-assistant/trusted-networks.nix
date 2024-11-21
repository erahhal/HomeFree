{ pkgs, ... }:
let
  ldap-auth-sh = pkgs.callPackage ./ldap-auth-sh.nix {};
in
{
  services.home-assistant.config.homeassistant.auth_providers = [
    {
      type = "trusted_networks";
      trusted_networks = [
        "10.0.0.0/8"
      ];
    }
  ];
}
