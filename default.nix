{ homefree-inputs, ... }:
{
  _module.args.homefree-inputs = homefree-inputs;

  imports = [
    homefree-inputs.nixos-generators.nixosModules.all-formats
    homefree-inputs.nixos-hardware.nixosModules.common-cpu-intel
    homefree-inputs.nixos-hardware.nixosModules.common-pc-laptop
    homefree-inputs.authentik-nix.nixosModules.default
    homefree-inputs.disko.nixosModules.disko
    homefree-inputs.nixvim.nixosModules.nixvim
    homefree-inputs.sops-nix.nixosModules.sops
    ./modules/ddclient-multi.nix
    ./module.nix
    ./hosts/homefree/configuration.nix
  ];
}
