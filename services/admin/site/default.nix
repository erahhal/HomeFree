{ pkgs, lib, buildNpmPackage, ... }:

buildNpmPackage {
  name = "admin";
  src = ./.;
  # npmDepsHash = lib.fakeHash;
  npmDepsHash = "sha256-shULp94RvPi6XBtf5+BL5J9zdnsjhxvcgXomAu9lTUY=";

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [
    "--legacy-peer-deps"
    "--loglevel=verbose"
  ];

  makeCacheWritable = true;

  nodejs = pkgs.nodejs_22;
}
