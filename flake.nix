{
  description = "HomeFree Self-Hosting Platform";

  inputs = {
    # Use stable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-editor.url = "github:vlinkz/nix-editor";

    sops-nix.url = "github:Mic92/sops-nix";

    adblock-unbound = {
      url = "github:MayNiklas/nixos-adblock-unbound";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      ## optional overrides. Note that using a different version of nixpkgs can cause issues, especially with python dependencies
      # inputs.nixpkgs.follows = "nixpkgs"
      # inputs.flake-parts.follows = "flake-parts"
    };

    # notnft = {
    #   url = "github:chayleaf/notnft";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    #
    # nixos-router = {
    #   url = "github:chayleaf/nixos-router";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { ... } @ inputs:
  let
    system = "x86_64-linux";
    # Can't use name "inputs" as it gets overridden by parent flakes that define inputs.nixpkgs.lib.nixosSystem
    homefree-inputs = inputs;
  in
  {
    nixosModules = rec {
      homefree = import ./default.nix { inherit homefree-inputs; inherit system; };
      imports = [ ];
      default = homefree;

      lan-client = import ./lan-client.nix { inherit homefree-inputs; inherit system; };
    };
  };
}
