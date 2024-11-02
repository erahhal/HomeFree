#!/usr/bin/env bash

## Import the user's SSH key into GPG

cp ~/.ssh/id_rsa /tmp/id_rsa
ssh-keygen -p -N "" -f /tmp/id_rsa
USER_GPG_FINGERPRINT=$(nix-shell --quiet -p gnupg -p ssh-to-pgp --run "ssh-to-pgp -private-key -i /tmp/id_rsa | gpg --import --quiet" 2>&1)
echo "${USER_GPG_FINGERPRINT}"
rm /tmp/id_rsa
# set ultimate trust level
# nix-shell --quiet -p gnupg --run "echo -e 'trust\n5\ny\n' | gpg --command-fd 0 --edit-key ${USER_GPG_FINGERPRINT}"
nix-shell --quiet -p gnupg --run "echo \"${USER_GPG_FINGERPRINT}:6:\" | gpg --import-ownertrust"

## Import the homefree host SSH key into GPG

# remove key from known_hosts
ssh-keygen -R "[localhost]:2223"
# Get GPG fingerprint of server RSA key
SERVER_GPG_FINGERPRINT=$(nix-shell --quiet -p gnupg -p ssh-to-pgp --run "ssh -o LogLevel=ERROR -o StrictHostKeychecking=no -p 2223 homefree@localhost \"sudo cat /etc/ssh/ssh_host_rsa_key\" | ssh-to-pgp -private-key | gpg --import --allow-non-selfsigned-uid --quiet" 2>&1 | head -n 1)
echo "${SERVER_GPG_FINGERPRINT}"
# set ultimate trust level
nix-shell --quiet -p gnupg --run "echo \"${SERVER_GPG_FINGERPRINT}:6:\" | gpg --import-ownertrust"

