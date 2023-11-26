HOSTNAME = $(shell hostname)

NIX_FILES = $(shell find . -name '*.nix' -type f)

# nixos-generate -f qcow --flake .#homefree
build:
	nix build .#nixosConfigurations.homefree.config.formats.qcow

