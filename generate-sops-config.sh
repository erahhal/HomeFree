#!/usr/bin/env bash

ssh -o LogLevel=ERROR -o StrictHostKeychecking=no -p 2223 homefree@localhost "mkdir -p ~/.ssh"
scp -P 2223 ~/.ssh/id_rsa homefree@localhost:/home/homefree/.ssh/id_rsa
scp -P 2223 ~/.ssh/id_rsa.pub homefree@localhost:/home/homefree/.ssh/id_rsa.pub

ssh -o LogLevel=ERROR -o StrictHostKeychecking=no -p 2223 homefree@localhost "cd ~/nixcfg/HomeFree; ./generate-sops-config-server.sh"

./generate-sops-config-host.sh
