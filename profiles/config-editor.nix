{ inputs, pkgs, system, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.nix-editor.packages.${system}.default
  ];
}
