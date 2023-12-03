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
		## 9p mount:
		# -virtfs local,path=./,mount_tag=mount_homefree_source,security_model=passthrough,id=mount_homefree_source \
	sudo cp /var/lib/libvirt/qemu/nvram/nixos_VARS.fd ./build/
	sudo chown erahhal:users ./build/nixos_VARS.fd
	virtiofsd --socket-path /tmp/vhostqemu --shared-dir ./ --cache auto &
	qemu-kvm \
		-chardev socket,id=char0,path=/tmp/vhostqemu \
		-device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=mount_homefree_source \
		-m 8G -object memory-backend-file,id=mem,size=8G,mem-path=/dev/shm,share=on \
		-numa node,memdev=mem \
		-drive file=/var/run/libvirt/nix-ovmf/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
		-drive file=./build/nixos_VARS.fd,if=pflash,format=raw,unit=1 \
		-hda ./build/homefree.qcow2 \
		-smp 4 \
		-m 8G \
		-net nic \
		-net user,hostfwd=tcp::2223-:22
