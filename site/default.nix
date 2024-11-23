{ buildNpmPackage, lib, ... }:

buildNpmPackage {
  name = "site";
  src = ./.;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-+laHFZIwVqx9A8lim6amX5HdfCFkgFiU5QHHScV5lSY=";
}
