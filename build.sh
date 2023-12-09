#!/usr/bin/env bash

set -e

HOSTNAME=$(hostname)
PLATFORM=$(sudo dmidecode -s system-manufacturer)

build_image() {
    HOST=$1
    nix build .#nixosConfigurations.${HOST}.config.formats.qcow
    mkdir -p ./build
    mv ./result ./${HOST}.qcow2
    rsync -L ./${HOST}.qcow2 ./build/${HOST}.qcow2
    chmod 750 ./build/${HOST}.qcow2
}

if [ $PLATFORM == "QEMU" ]; then
    sudo nixos-rebuild switch --flake .#${HOSTNAME} -L
else
    build_image homefree
    qemu-img resize ./build/homefree.qcow2 +32G
    build_image lan-client
fi
