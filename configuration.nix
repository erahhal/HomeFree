{ config, lib, ... }:
{
  imports = [
    ./profiles/acme.nix
    ./profiles/bash.nix
    ./profiles/common.nix
    ./profiles/config-editor.nix
    ./profiles/git.nix
    ./profiles/hardware-configuration.nix
    ./profiles/router.nix
    ./profiles/traffic-control.nix
    ./profiles/virtualisation.nix

    ## System services
    ## @TODO: Evaluate if any can be moved to podman
    ./services/admin
    ./services/backup.nix
    ./services/caddy.nix
    ./services/ddclient.nix
    ./services/dnsmasq.nix
    ./services/headscale.nix
    ./services/landing-page
    ./services/unbound.nix

    ## Shared services
    ## @TODO: Evaluate if any can be moved to podman
    ./services/mqtt.nix
    ./services/mysql.nix
    ./services/postgres.nix

    ## Podman-based services
    ./services/adguardhome-podman.nix
    ./services/baikal-podman.nix
    ./services/cryptpad-podman.nix
    ./services/forgejo-podman.nix
    ./services/frigate-podman.nix
    ./services/grocy-podman.nix
    ./services/home-assistant-podman.nix
    ./services/homebox-podman.nix
    ./services/joplin-podman.nix
    ./services/kanidm-podman.nix
    ./services/immich-podman.nix
    ./services/logseq-podman.nix
    ./services/lidarr-podman.nix
    # ./services/mongo-podman.nix
    ./services/nzbget-podman.nix
    ./services/ollama-podman.nix
    ./services/radicale-podman.nix
    ./services/snipe-it-podman.nix
    ./services/unifi-podman.nix
    ./services/vaultwarden-podman.nix
    ./services/zitadel-podman.nix

    ## @TODO: Move to podman
    ## Otherwise entire system needs to be upgraded to upgrade individual app
    # ./services/adguardhome.nix
    ./services/authentik.nix
    ./services/gitea.nix
    ./services/jellyfin.nix
    ./services/linkwarden.nix
    ./services/matrix.nix
    ./services/nextcloud.nix

    ## Temporary fixes
    ./provisional/hypothesis.nix
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


