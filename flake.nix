{
  description = "HomeFree Self-Hosting Platform";

  inputs = {
    # Use stable for main
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

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

    adblock-unbound = {
      url = "github:MayNiklas/nixos-adblock-unbound";
      inputs.nixpkgs.follows = "nixpkgs";
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
          # inputs.nixos-router.nixosModules.default
          # inputs.notnft.lib.${system}

          (import ./hosts/homefree/configuration.nix)
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
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
