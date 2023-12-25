#!/usr/bin/env bash

set -e

if ! command -v nix &> /dev/null
then
    echo "nix could not be found. If it is installed, you may need to log out and log in again for it to be in your path."
    exit 1
fi

build_image() {
    HOST=$1
    nix build .#nixosConfigurations.${HOST}.config.formats.qcow
    mkdir -p ./build
    mv ./result ./${HOST}.qcow2
    rsync -L ./${HOST}.qcow2 ./build/${HOST}.qcow2
    chmod 750 ./build/${HOST}.qcow2
}

build_image homefree
qemu-img resize ./build/homefree.qcow2 +32G
build_image lan-client
