{ ... }:
{
  # https://github.com/NixOS/nixpkgs/issues/393637

  ## Get rid of build warning. This will eventually be merged with the Linkwarden package.
  nixpkgs.overlays = [(
    final: prev: {
      final.python312Packages = prev.python312Packages.overrideAttrs (finalAttrs: previousAttrs: {
        # fix Hypothesis timeouts
        preCheck = ''
          echo >> tests/conftest.py <<EOF

          import hypothesis

          hypothesis.settings.register_profile(
            "ci",
            deadline=None,
            print_blob=True,
            derandomize=True,
          )
          EOF
        '';

        pytestFlagsArray = [
          "tests"
          "--hypothesis-profile"
          "ci"
        ];
      });
    }
  )];
}
