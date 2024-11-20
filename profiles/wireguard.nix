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

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      postSetup = ''
        # ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o ${config.homefree.network.wan-interface} -j MASQUERADE
        ${pkgs.nftables}/bin/nft add rule inet nat postrouting oifname "${config.homefree.network.wan-interface}" ip saddr 192.168.2.0/24 counter masquerade
      '';

      # This undoes the above command
      postShutdown = ''
        # ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.2.0/24 -o ${config.homefree.network.wan-interface} -j MASQUERADE
        HANDLE=$(${pkgs.nftables}/bin/nft -a list chain inet nat postrouting | ${pkgs.gnugrep}/bin/grep "192.168.2.0" | ${pkgs.gawk}/bin/awk '/# handle [0-9]+/ {print $NF}')
        ${pkgs.nftables}/bin/nft delete rule inet nat postrouting handle $HANDLE
      '';

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
