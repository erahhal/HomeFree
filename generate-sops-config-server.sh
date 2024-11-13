#!/usr/bin/env bash

## @TODO: consolidate to single script that works on host or on guest
## @TODO: If no user key on guest, complain and abort
## @TODO: Fix error messages that mess with getting fingerprit
## @TODO: Make sure uid matches <curruser>@localhost, as it tells sops where to look for keyring
##   https://www.reddit.com/r/GnuPG/comments/m76to1/is_there_a_way_to_change_the_name_on_a_key_pair/

## Import the user's SSH key into GPG

# cp ~/.ssh/id_rsa /tmp/id_rsa
# ssh-keygen -p -N "" -f /tmp/id_rsa
# USER_GPG_FINGERPRINT=$(nix-shell --quiet -p gnupg -p ssh-to-pgp --run "ssh-to-pgp -private-key -i /tmp/id_rsa | gpg --import --allow-non-selfsigned-uid --quiet" 2>&1 | head -2 | tail -1)
# echo "${USER_GPG_FINGERPRINT}"
# rm /tmp/id_rsa
# # set ultimate trust level
# # nix-shell --quiet -p gnupg --run "echo -e 'trust\n5\ny\n' | gpg --command-fd 0 --edit-key ${USER_GPG_FINGERPRINT}"
# nix-shell --quiet -p gnupg --run "echo \"${USER_GPG_FINGERPRINT}:6:\" | gpg --import-ownertrust"
#
# ## Import the homefree host SSH key into GPG
#
# # remove key from known_hosts
# ssh-keygen -R "[localhost]:2223"
# # Get GPG fingerprint of server RSA key
# SERVER_GPG_FINGERPRINT=$(nix-shell --quiet -p gnupg -p ssh-to-pgp --run "sudo cat /etc/ssh/ssh_host_rsa_key | ssh-to-pgp -private-key | gpg --import --allow-non-selfsigned-uid --quiet" 2>&1 | head -2 | tail -1)
# # set ultimate trust level
# nix-shell --quiet -p gnupg --run "echo \"${SERVER_GPG_FINGERPRINT}:6:\" | gpg --import-ownertrust"
#
# # This example uses YAML anchors which allows reuse of multiple keys
# # without having to repeat yourself.
# # Also see https://github.com/Mic92/dotfiles/blob/master/nixos/.sops.yaml
# # for a more complex example.
# cat > .sops.yaml << EOF
# #  see https://github.com/Mic92/dotfiles/blob/master/nixos/.sops.yaml
# keys:
#   - &user_homefree $USER_GPG_FINGERPRINT
#   - &server_homefree $SERVER_GPG_FINGERPRINT
# creation_rules:
#   - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
#     key_groups:
#     - pgp:
#       - *user_homefree
#       - *server_homefree
#   - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
#     key_groups:
#     - pgp:
#       - *user_homefree
#       - *server_homefree
#   - path_regex: secrets/homefree/[^/]+\.(yaml|json|env|ini)$
#     key_groups:
#     - pgp:
#       - *user_homefree
#       - *server_homefree
# EOF

for config in $(find secrets -name '*.yaml'); do
    nix-shell -p sops --run "sops updatekeys $config"
done
