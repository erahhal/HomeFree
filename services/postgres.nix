{ lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    # Authentik sets an older package for some reason
    package = lib.mkForce pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust

      #type database DBuser origin-address auth-method
      # ipv4
      host  all      all     127.0.0.1/32   trust
      # ipv6
      host all       all     ::1/128        trust
    '';
  };
}
