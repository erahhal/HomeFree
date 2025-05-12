{ config, pkgs, ... }:
let
  username = config.homefree.docker-io-auth.username;
  passwordFile = config.homefree.docker-io-auth.secrets.password;
in
{
  system.activationScripts.podmanAuth = if config.homefree.docker-io-auth.enable == true then ''
    mkdir -p /root/.docker
    PASSWORD=$(cat ${passwordFile})
    ENCODED=$(echo -n "${username}:$PASSWORD" | ${pkgs.coreutils}/bin/base64)
    cat >/root/.docker/config.json << EOF
    {
      "auths": {
        "docker.io": {
          "auth": "$ENCODED"
        }
      }
    }
    EOF
    chmod 600 /root/.docker/config.json
    mkdir -p /var/lib/containers
    cp /root/.docker/config.json /var/lib/containers/auth.json
    chmod 600 /var/lib/containers/auth.json
  '' else "";

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
