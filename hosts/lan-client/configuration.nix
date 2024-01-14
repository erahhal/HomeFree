{ inputs, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../../profiles/common.nix
    ../../profiles/hardware-configuration.nix
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
  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "lan-client";
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

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------
}


