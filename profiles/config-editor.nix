{ homefree-inputs, system, pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      nix-editor = homefree-inputs.nix-editor.packages.${system}.default;
    })
  ];
  environment.systemPackages = [
    pkgs.nix-editor
  ];
}
