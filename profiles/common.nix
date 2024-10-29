{ homefree-inputs, pkgs, system, ...}:
{

  # --------------------------------------------------------------------------------------
  # Base Nix config
  # --------------------------------------------------------------------------------------

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  # @TODO: Could this be useful for auto-upgrading systems out there?
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = true;
  #   flake = "github:erahhal/nixcfg";
  #   flags = [
  #     "--recreate-lock-file"
  #     "-no-write-lock-file"
  #     "-L" # print build logs
  #   ];
  #   dates = "daily";
  # };

  nix = {
    nixPath = [ "nixpkgs=${homefree-inputs.nixpkgs}" "nixos-config=/home/homefree/nixcfg" ];

    # Which package collection to use system-wide.
    package = pkgs.nixFlakes;

    settings = {
      # sets up an isolated environment for each build process to improve reproducibility.
      # Disallow network callsoutside of fetch* and files outside of the Nix store.
      sandbox = true;
      # Automatically clean out old entries from nix store by detecting duplicates and creating hard links.
      # Only starts with new derivations, so run "nix-store --optimise" to clear out older cruft.
      # optimise.automatic = true below should handle this.
      auto-optimise-store = true;
      # Users with additional Nix daemon rights.
      # Can specify additional binary caches, import unsigned NARs (Nix Archives).
      trusted-users = [ "@wheel" "root" ];
      # Users allowed to connect to Nix daemon
      allowed-users = [ "@wheel" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    # Additional text appended to nix.conf
    extraOptions =
      let empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}''; in
      ''
        # Enable flakes
        experimental-features = nix-command flakes recursive-nix
        flake-registry = ${empty_registry}

        builders-use-substitutes = true

        # Prevents garbage collector from deleting derivations.
        # Useful for querying and tracing options and dependencies for a store path.
        # https://ianthehenry.com/posts/how-to-learn-nix/saving-your-shell/
        keep-derivations = true

        # Prevents garbage collector from deleting outputs of derivations.
        keep-outputs = true
      '';

    registry.nixpkgs.flake = homefree-inputs.nixpkgs;

    # Garbage collection - deletes all unreachable paths in Nix store.
    gc = {
      # Run garbage collection automatically
      automatic = true;
      # Run once a week
      dates = "weekly";
      # Delete older than 7 days, stopping after "max-freed" bytes
      options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
    };
    # Optimiser settings
    # It seems that this is a scheduled job, as opposed to "autoOptimiseStore", which runs just in time.
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # --------------------------------------------------------------------------------------
  # User config
  # --------------------------------------------------------------------------------------

  users.users.homefree = {
    isNormalUser  = true;
    home  = "/home/homefree";
    description  = "Homefree User";
    extraGroups  = [ "wheel" ];
    # @TODO: Make this dynamic, not hard coded
    openssh.authorizedKeys.keys  = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNvmGn1/uFnfgnv5qsec0GC04LeVB1Qy/G7WivvvUZVBBDzp8goe1DsE8M8iqnBSin56gQZDWsd50co2MbFAWuqH2HxY7OGay7P/V2q+SziTYFva85WGl84qWvYMmdB+alAFBT3L4eH5cegC5NhNp+OGsQuq32RdojgXXQt6vyZnaOypuz90k3rqV6Rt+iBTLz6VziasCLcYydwOvi9f1q6YQwGPLKaupDrV6gxvoX9bXLdopqwnXPSE/Eqczxgwc3PefvAJPSd6TOqIXvbtpv/B3Evt5SPe2gq+qASc5K0tzgra8KAe813kkpq4FuKJzHbT+EmO70wiJjru7zMEhd erahhal@nfml-erahhalQFL" ];
    hashedPassword = "$6$5.6V9H0g5F47ubUm$e0N.GXZ9eoqmvpO9MjZlCISC9IIxKKcf0xtnuFyuXSQEQlfaazrS4kBhplDB6GCsQgwpOxdrX2DmcwbMiX/h30";
  };

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  # --------------------------------------------------------------------------------------
  # Package config
  # --------------------------------------------------------------------------------------

  nixpkgs = {
    hostPlatform = system;
  };

  # --------------------------------------------------------------------------------------
  # Boot / Kernel
  # --------------------------------------------------------------------------------------

  # Disables writing to Nix store by mounting read-only. "false" should only be used as a last resort.
  # Nix mounts read-write automatically when it needs to write to it.
  boot.readOnlyNixStore = true;

  # --------------------------------------------------------------------------------------
  # Services
  # --------------------------------------------------------------------------------------

  # Firmware/BIOS updates
  services.fwupd.enable = true;

  # Setting to true will kill things like tmux on logout
  services.logind.killUserProcesses = false;

  services.gvfs.enable = true; # SMB mounts, trash, and other functionality
  services.tumbler.enable = true; # Thumbnail support for images

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # @TODO: Move to "environment"?
  services.printing.drivers = [ pkgs.brlaser ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This will save you money and possibly your life!
  services.thermald.enable = true;

  services.upower.enable = true;

  # Enable power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # --------------------------------------------------------------------------------------
  # i18n
  # --------------------------------------------------------------------------------------

  # @TODO: Make this UI configurable
  i18n.defaultLocale = "en_US.UTF-8";

  # --------------------------------------------------------------------------------------
  # Networking
  # --------------------------------------------------------------------------------------

  networking.search = [ "localdomain" ];

  # --------------------------------------------------------------------------------------
  # Base Packages
  # --------------------------------------------------------------------------------------

  programs.nix-ld.enable = true;

  programs.mosh.enable = true;

  # environment.variables.EDITOR = "neovim";
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  environment.interactiveShellInit = ''
    alias vi='nvim'
    alias vim='nvim'
  '';

  environment.systemPackages = with pkgs; [
    at-spi2-core
    backblaze-b2
    bashmount
    bfg-repo-cleaner
    bind
    ccze             # readable parsed system logs
    cpufrequtils
    distrobox
    dmidecode
    dos2unix
    exfat
    exiftool
    ffmpeg
    file
    fio
    fx                # Terminal-based JSON viewer and processor
    gcc
    git
    git-lfs
    gnumake
    htop
    hwinfo
    iftop
    inetutils
    iotop
    iperf3
    luarocks
    lshw
    lsof
    lxqt.lxqt-policykit # For GVFS
    iw
    iwd
    jhead
    memtest86plus
    minicom
    neofetch
    neovim
    nil
    nix-index
    openssl
    # openjdk16-bootstrap
    p7zip
    pciutils
    powertop
    sshpass
    steampipe
    tmux
    usbutils
    utillinux
    vulnix
    wireguard-tools
    wget
    xz
    zip
    zsh
  ];
}
