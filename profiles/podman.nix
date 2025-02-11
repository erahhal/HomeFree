{ ... }:
{
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      autoPrune.enable = true;

      defaultNetwork.settings = {
        # Required for containers under podman-compose to be able to talk to each other.
        dns_enabled = true;
        ipv6_enabled = true;
        # subnet = "10.88.0.0/16";
        subnets = [
          {
            subnet = "10.88.0.0/16";
            gateway = "10.88.0.1";
          }
          {
            subnet = "fd00::/64";
            gateway = "fd00::1";
          }
        ];
      };
    };
  };
}
