{ inputs, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ./profiles/common.nix
    ./profiles/hardware-configuration.nix
    ./profiles/virtual-machine.nix
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
    # Set font size early
    efi = {
      canTouchEfiVariables = true;
    };
  };

  # --------------------------------------------------------------------------------------
  # File system
  # --------------------------------------------------------------------------------------

  # @TODO: Setup luks or some disk encryption (ZFS?)


  # --------------------------------------------------------------------------------------
  # Device specific
  # --------------------------------------------------------------------------------------

  # @TODO: Make this UI configurable
  time.timeZone = "America/Los_Angeles";

  networking = {
    # @TODO: Make this UI configurable
    hostName = "homefree";
    useNetworkd = true;
    networkmanager = {
      enable = true;
    };
    wireless = {
      # Disable wpa_supplicant
      enable = false;
    };
  };

  # --------------------------------------------------------------------------------------
  # Hardware specific
  # --------------------------------------------------------------------------------------
}


