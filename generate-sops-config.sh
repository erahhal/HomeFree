#!/usr/bin/env bash

cp ~/.ssh/id_rsa /tmp/id_rsa
ssh-keygen -p -N "" -f /tmp/id_rsa
USER_GPG_FINGERPRINT=$(nix-shell -p gnupg -p ssh-to-pgp --run "ssh-to-pgp -private-key -i ~/.ssh/id_rsa | gpg --import --quiet" 2>&1)
rm /tmp/id_rsa

ssh-keygen -R "[localhost]:2223"
SERVER_GPG_FINGERPRINT=$(ssh -o StrictHostKeychecking=no -p 2223 homefree@localhost "sudo cat /etc/ssh/ssh_host_rsa_key" | nix-shell -p ssh-to-pgp --run "ssh-to-pgp -o homefree.asc" 2>&1)

# This example uses YAML anchors which allows reuse of multiple keys
# without having to repeat yourself.
# Also see https://github.com/Mic92/dotfiles/blob/master/nixos/.sops.yaml
# for a more complex example.
cat > .sops.yaml << EOF
keys:
  - &user_homefree $USER_GPG_FINGERPRINT
  - &server_homefree $SERVER_GPG_FINGERPRINT
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - pgp:
      - *user_homefree
      - *server_homefree
  - path_regex: secrets/homefree/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - pgp:
      - *user_homefree
      - *server_homefree
EOF
