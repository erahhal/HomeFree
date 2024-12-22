{ pkgs, buildNpmPackage, ... }:

buildNpmPackage {
  name = "admin";
  src = ./.;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-C7dFRyWooP920Ei4JeK10fL93zJN5XQu85+Tz6oU0fA=";

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [
    "--legacy-peer-deps"
    "--loglevel=verbose"
  ];

  makeCacheWritable = true;

  nodejs = pkgs.nodejs_22;
}
