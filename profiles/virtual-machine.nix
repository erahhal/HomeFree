{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libvirt
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

  boot.extraModprobeConfig = "options kvm_intel nested=1";
  boot.kernelParams = [
    "intel_iommu=on"
    "cgroup_enable=freezer"
  ];
}
