{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./.;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-w/uQ+FVHu9/pwwgKAvManocPKUAOHcFmBIG18pUDu14=";
}
