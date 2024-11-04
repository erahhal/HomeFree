{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  services.unifi = {
    enable = true;
    openFirewall = true;
    unifiPackage = pkgs.unifi8;
  };
}

