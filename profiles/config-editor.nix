{ homefree-inputs, system, ... }:
{
  environment.systemPackages = [
    homefree-inputs.nix-editor.packages.${system}.default
  ];
}
