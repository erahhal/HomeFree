{ config, pkgs, ... }:
{
  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = config.homefree.network.wan-interface;
  networking.nat.internalInterfaces = [ config.homefree.network.lan-interface ];
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    "${config.homefree.network.lan-interface}"= {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = [ "192.168.3.1/24" ];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.3.0/24 -o ${config.homefree.network.wan-interface} -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.3.0/24 -o ${config.homefree.network.wan-interface} -j MASQUERADE
      '';

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "path to private key file";

      peers = config.homefree.wireguard.peers;
    };
  };
}
