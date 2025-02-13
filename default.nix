{ homefree-inputs, ... }:
{
  _module.args.homefree-inputs = homefree-inputs;

  imports = [
    homefree-inputs.nixos-generators.nixosModules.all-formats
    homefree-inputs.nixos-hardware.nixosModules.common-cpu-intel
    homefree-inputs.nixos-hardware.nixosModules.common-pc-laptop
    homefree-inputs.authentik-nix.nixosModules.default
    homefree-inputs.disko.nixosModules.disko
    homefree-inputs.sops-nix.nixosModules.sops
    homefree-inputs.nixvim-config.nixosModules.default
    ./modules/ddclient-multi.nix
    ./module.nix
    ./configuration.nix
  ];
}
