HOSTNAME = $(shell hostname)

NIX_FILES = $(shell find . -name '*.nix' -type f)

.PHONY: all build run rebuild

all: build

build:
	nix build .#nixosConfigurations.homefree.config.formats.qcow
	mkdir -p ./build
	rsync -L ./result ./build/homefree.qcow2
	chmod 750 ./build/homefree.qcow2

run:
	qemu-system-x86_64 -smbios type=0,uefi=on -smp 4 -m 8192 -hda ./build/homefree.qcow2 -net user,hostfwd=tcp::2222-:22 -net nic

rebuild:
	sudo nixos-rebuild switch --flake .#${HOSTNAME} -L
