#!/usr/bin/env bash

nix-shell --quiet -p gnupg -p ssh-to-pgp --run "ssh-to-pgp -private-key -i ~/.ssh/id_rsa | gpg --import --quiet"
nix-shell --quiet -p gnupg -p ssh-to-pgp --run "ssh -o StrictHostKeychecking=no -p 2223 homefree@localhost \"sudo cat /etc/ssh/ssh_host_rsa_key\" | ssh-to-pgp -private-key | gpg --import --quiet"
