{
  description = "HomeFree Instance";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    homefree.url = "github:erahhal/HomeFree";
  };

  outputs = {
    self,
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
          inputs.homefree.nixosModules.default
        ];
        specialArgs = {
          inherit inputs;
          inherit system;
        };
      };
    };
  };
}
