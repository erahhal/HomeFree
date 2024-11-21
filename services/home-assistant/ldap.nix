{ pkgs, ... }:
let
  ldap-auth-sh = pkgs.callPackage ./ldap-auth-sh.nix {};
in
{
  services.home-assistant.config.homeassistant.auth_providers = [
    {
      type = "command_line";
      command = "${ldap-auth-sh}/bin/ldap-auth.sh";
      meta = true;
    }
  ];
}
