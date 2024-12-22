{ buildNpmPackage, ... }:

buildNpmPackage {
  name = "default-landing-page";
  src = ./.;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-uOLu/MrHS+Et9yUyZO66ANRCzG15hki+7oSTqw4eyT0=";
}
