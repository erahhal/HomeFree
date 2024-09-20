{
  description = "HomeFree Self-Hosting Platform";

  inputs = {
    # Use stable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Trails trunk - latest packages with broken commits filtered out
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Very latest packages - some commits broken
    nixpkgs-trunk.url = "github:NixOS/nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-editor.url = "github:vlinkz/nix-editor";

    agenix.url = "github:ryantm/agenix";

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

  outputs = {
    self,
    nixos-generators,
    nixos-hardware,
    nixpkgs,
    agenix,
    sops-nix,
    authentik-nix,
    ...
  }@inputs:
  {
    nixosConfigurations = {
      homefree =
      let
        system = "x86_64-linux";
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          agenix.nixosModules.default
          sops-nix.nixosModules.sops
          authentik-nix.nixosModules.default
          # inputs.nixos-router.nixosModules.default
          # inputs.notnft.lib.${system}

          (import ./hosts/homefree/configuration.nix)
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
          inherit agenix;
          inherit sops-nix;
        };
      };
      lan-client =
      let
        system = "x86_64-linux";
      in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-laptop

          (import ./hosts/lan-client/configuration.nix)
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
        };
      };
    };
  };
}
