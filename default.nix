{ homefree-inputs, ... }:
{
  _module.args.homefree-inputs = homefree-inputs;

  imports = [
    homefree-inputs.nixos-generators.nixosModules.all-formats
    homefree-inputs.nixos-hardware.nixosModules.common-cpu-intel
    homefree-inputs.nixos-hardware.nixosModules.common-pc-laptop
    homefree-inputs.sops-nix.nixosModules.sops
    homefree-inputs.authentik-nix.nixosModules.default
    homefree-inputs.nixvim.nixosModules.nixvim
    ./module.nix
    ./hosts/homefree/configuration.nix
  ];
}
