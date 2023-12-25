#!/usr/bin/env bash

set -e

HOSTNAME=$(hostname)

if ! command -v nix &> /dev/null
then
    echo "nix could not be found. If it is installed, you may need to log out and log in again for it to be in your path."
    exit 1
fi

sudo nixos-rebuild switch --flake .#${HOSTNAME} -L
