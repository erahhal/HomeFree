{ config, pkgs, ... }:
let
  listenPort = config.homefree.wireguard.listenPort;
in
{
  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = config.homefree.network.wan-interface;
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ listenPort ];
  };

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "192.168.2.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = listenPort;

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "/run/secrets/wireguard/server-private-key";

      peers = config.homefree.wireguard.peers;
    };
  };

  ## @TODO: Move to host config
  sops.secrets = {
    "wireguard/server-private-key" = {
      format = "yaml";
      sopsFile = ../secrets/wireguard.yaml;

      owner = config.homefree.system.adminUsername;
      path = "/run/secrets/wireguard/server-private-key";
    };
  };
}
