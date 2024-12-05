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
        subnet = "10.88.0.0/16";
      };
    };
  };
}
