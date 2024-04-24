#!/usr/bin/env bash

ssh-keygen -R "[localhost]:2223"
ssh -o StrictHostKeychecking=no -p 2223 homefree@localhost "sudo cat /etc/ssh/ssh_host_rsa_key" | nix-shell -p ssh-to-pgp --run "ssh-to-pgp -o homefree-server.asc"
