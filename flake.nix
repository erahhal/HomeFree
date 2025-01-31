{
  description = "HomeFree Self-Hosting Platform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-editor.url = "github:snowfallorg/nix-editor";

    sops-nix.url = "github:Mic92/sops-nix";

    adblock-unbound = {
      url = "github:MayNiklas/nixos-adblock-unbound";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      # url = "github:nix-community/authentik-nix";
      # url = "github:nix-community/authentik-nix/version/2024.10.4";
      # url = "github:erahhal/authentik-nix/no-docs";
      url = "github:erahhal/authentik-nix/daba454bd25cea9796e525d225f06fb0782abba6";

      ## optional overrides. Note that using a different version of nixpkgs can cause issues, especially with python dependencies
      # inputs.flake-parts.follows = "flake-parts";
    };

    # nixos-router = {
    #   url = "github:chayleaf/nixos-router";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, ... } @ inputs:
  let
    system = "x86_64-linux";
    # Can't use name "inputs" as it gets overridden by parent flakes that define inputs.nixpkgs.lib.nixosSystem
    homefree-inputs = inputs;
    # versionInfo = import ./version.nix;
    # version = versionInfo.version + (inputs.nixpkgs.lib.optionalString (!versionInfo.released) "-dirty");
  in
  {
    nixosModules = rec {
      homefree = import ./default.nix { inherit homefree-inputs; inherit system; };
      imports = [ ];
      default = homefree;
      lan-client = import ./lan-client.nix { inherit homefree-inputs; inherit system; };
    };
    nixosConfigurations = {
      homefree-test = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          self.nixosModules.homefree
        ];
      };
      lan-client = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          self.nixosModules.lan-client
        ];
      };
    };
  };
}
