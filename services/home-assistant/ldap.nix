{ pkgs, ... }:
let
  ldap-auth-sh = pkgs.callPackage ./ldap-auth-sh.nix {};
in
{
  ## https://community.home-assistant.io/t/hassos-ldap-command-line-authentication-over-ssh/228852/4
  services.home-assistant.config.homeassistant.auth_providers = [
    {
      type = "command_line";
      command = "${ldap-auth-sh}/bin/ldap-auth.sh";
      meta = true;
    }
  ];
}
