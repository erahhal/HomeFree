HOSTNAME = $(shell hostname)

NIX_FILES = $(shell find . -name '*.nix' -type f)

PLATFORM = $(shell sudo dmidecode -s system-manufacturer)

.PHONY: all build run rebuild

all: build

build:
ifeq ($(PLATFORM), QEMU)
	sudo nixos-rebuild switch --flake .#${HOSTNAME} -L
else
	nix build .#nixosConfigurations.homefree.config.formats.qcow
	mkdir -p ./build
	rsync -L ./result ./build/homefree.qcow2
	chmod 750 ./build/homefree.qcow2
	qemu-img resize ./build/homefree.qcow2 +32G
endif

run:
	# qemu-system-x86_64 -smbios type=0,uefi=on -smp 4 -m 8192 -hda ./build/homefree.qcow2 -net user,hostfwd=tcp::2222-:22 -net nic
	# -bios /var/run/libvirt/nix-ovmf/OVMF_CODE.fd \
	# -bios /var/lib/libvirt/qemu/nvram/nixos_VARS.fd \
	# -drive file=/var/run/libvirt/nix-ovmf/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
	# -drive file=/var/lib/libvirt/qemu/nvram/nixos_VARS.fd,if=pflash,format=raw,unit=1 \
	# -hda ./build/homefree.qcow2 \
	sudo cp /var/lib/libvirt/qemu/nvram/nixos_VARS.fd ./build/
	sudo chown erahhal:users ./build/nixos_VARS.fd
	qemu-system-x86_64 \
		-enable-kvm \
		-machine q35 \
		-cpu host \
		-object memory-backend-memfd,id=mem,size=4G,share=on \
		-drive file=/var/run/libvirt/nix-ovmf/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
		-drive file=./build/nixos_VARS.fd,if=pflash,format=raw,unit=1 \
		-hda ./build/homefree.qcow2 \
		-smp 4 \
		-m 8192 \
		-net user,hostfwd=tcp::2222-:22 \
		-net nic
