{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    virtiofsd
  ];

  systemd.mounts = [
    {
      what = "mount_homefree_source";
      where = "/home/homefree/nixcfg";
      type = "virtiofs";
      wantedBy = [ "multi-user.target" ];
      enable = true;
    }
  ];
}
