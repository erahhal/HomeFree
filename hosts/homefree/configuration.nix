{ inputs, lib, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    # ../../profiles/agenix.nix
    ../../profiles/authentik.nix
    ../../profiles/common.nix
    ../../profiles/config-editor.nix
    ../../profiles/ddclient.nix
    ../../profiles/home-assistant
    ../../profiles/hardware-configuration.nix
    ../../profiles/hosting.nix
    ../../profiles/postgres.nix
    ../../profiles/router.nix
    ../../profiles/virtual-machine.nix
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
  time.timeZone = lib.mkForce "America/Los_Angeles";

  networking = {
    # @TODO: Make this UI configurable
    hostName = "homefree";
    ## NetworkManager disabled in favor of networkd
    useNetworkd = true;
    wireless = {
      # Disable wpa_supplicant
      enable = false;
    };
    interfaces = {
      ens3.useDHCP = true;
    };
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


