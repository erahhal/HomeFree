{ config, lib, ... }:
{
  imports = [
    ../../profiles/acme.nix
    ../../profiles/common.nix
    ../../profiles/config-editor.nix
    ../../profiles/git.nix
    ../../profiles/hardware-configuration.nix
    ../../profiles/hosting.nix
    ../../profiles/nixvim.nix
    ../../profiles/podman.nix
    ../../profiles/router.nix
    # ../../profiles/traffic-shaping.nix
    ../../profiles/traffic-control.nix

    ../../services/adguardhome.nix
    ../../services/authentik.nix
    ../../services/backup.nix
    ../../services/baikal.nix
    ../../services/cryptpad.nix
    ../../services/ddclient.nix
    ../../services/dnsmasq.nix
    ../../services/frigate-podman.nix
    ../../services/gitea.nix
    ../../services/home-assistant
    ../../services/headscale.nix
    ../../services/headscale-ui.nix
    ../../services/immich.nix
    ../../services/jellyfin.nix
    ../../services/linkwarden.nix
    ../../services/matrix.nix
    ../../services/mqtt.nix
    ../../services/nextcloud.nix
    ../../services/postgres.nix
    ../../services/radicale.nix
    ../../services/unbound.nix
    ../../services/unifi.nix
    ../../services/vaultwarden.nix
  ];

  # --------------------------------------------------------------------------------------
  # Boot
  # --------------------------------------------------------------------------------------

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      # Use maximum resolution in systemd-boot for hidpi
      consoleMode = "max";
    };
    efi = {
      canTouchEfiVariables = true;
    };
  };

  # --------------------------------------------------------------------------------------
  # File system
  # --------------------------------------------------------------------------------------

  # @TODO: Setup luks or some disk encryption (ZFS?)

  # --------------------------------------------------------------------------------------
  # Network
  # --------------------------------------------------------------------------------------

  # Prevent hanging when waiting for network to be up
  systemd.network.wait-online.anyInterface = true;

  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  # @TODO: Make this UI configurable
  ## Must be forced due to Authentik hard coding a value of UTC
  time.timeZone = lib.mkForce config.homefree.system.timeZone;

  networking = {
    # @TODO: Make this UI configurable
    hostName = config.homefree.system.hostName;
    ## NetworkManager disabled in favor of networkd
    useNetworkd = true;
    # wireless = {
    #   # Disable wpa_supplicant
    #   enable = false;
    # };
  };

  # services.openssh.hostKeys = [
  #   {
  #     bits = 4096;
  #     openSSHFormat = true;
  #     path = "/etc/ssh/ssh_host_rsa_key";
  #     rounds = 100;
  #     type = "rsa";
  #   }
  # ];

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------
}


