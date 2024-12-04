{ pkgs, ... }:
{
  ## Get rid of build warning. This will eventually be merged with the Linkwarden package.
  nixpkgs.overlays = with pkgs; [(
    final: prev: {
      prisma = prev.prisma.overrideAttrs (finalAttrs: previousAttrs: {
        mainProgram = "prisma";
      });
    }
  )];
}