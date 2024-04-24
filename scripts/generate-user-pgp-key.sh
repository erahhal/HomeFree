#!/usr/bin/env bash

# Adds to ~/.gnupg/pubring.kbx
# List with: gpg -k
nix-shell -p gnupg -p ssh-to-pgp --run "ssh-to-pgp -private-key -i $HOME/.ssh/id_rsa | gpg --import --quiet"
# Exports public key from private key
# nix-shell -p ssh-to-pgp --run "ssh-to-pgp -i $HOME/.ssh/id_rsa -o $USER.asc"
