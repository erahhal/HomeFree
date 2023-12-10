#!/usr/bin/env bash

# TAP - Test Access Point, layer 2, data link layer, ethernet frames
# TUN - Network TUNnel, layer 3, network layer, ip packets
# Bridge - connects two network segments, like a super simple switch
# virbr0 - NAT bridge provided by libvirt, created by default network using virsh

# See: https://wiki.qemu.org/Documentation/Networking
# See: https://gist.github.com/extremecoders-re/e8fd8a67a515fee0c873dcafc81d811c
# See: https://blog.stefan-koch.name/2020/10/25/qemu-public-ip-vm-with-tap
# Setting up two VMs connected by bridge: https://futurewei-cloud.github.io/ARM-Datacenter/qemu/network-aarch64-qemu-guests/
    ## 9p mount:
    # -virtfs local,path=./,mount_tag=mount_homefree_source,security_model=passthrough,id=mount_homefree_source \
    ## user networking. nic set up guest interface, user NATs to host
    # -net nic \
    # -net user,hostfwd=tcp::2223-:22,hostfwd=tcp::8445-:443
    ## No GUI
    # -display egl-headless \
    # -netdev tap,id=enp1s0,ifname=tap-wan,script=no,downscript=no \
    # -netdev tap,id=enp2s0,ifname=tap-lan,script=no,downscript=no \

# @TODO: need to move to netdev bridge type?
# SEE: https://futurewei-cloud.github.io/ARM-Datacenter/qemu/network-aarch64-qemu-guests/
sudo cp /var/lib/libvirt/qemu/nvram/nixos_VARS.fd ./build/
sudo chown erahhal:users ./build/nixos_VARS.fd
virtiofsd --socket-path /tmp/vhostqemu --shared-dir ./ --cache auto &
pids[1]=$!
    # -netdev tap,id=enp1s0,br=hfbr0,helper=$(which qemu-bridge-helper) \
    # -device e1000,netdev=enp1s0,mac=52:53:54:55:56:01 \
sudo -E qemu-kvm \
    -chardev socket,id=char0,path=/tmp/vhostqemu \
    -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=mount_homefree_source \
    -m 8G -object memory-backend-file,id=mem,size=8G,mem-path=/dev/shm,share=on \
    -numa node,memdev=mem \
    -drive file=/var/run/libvirt/nix-ovmf/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
    -drive file=./build/nixos_VARS.fd,if=pflash,format=raw,unit=1 \
    -hda ./build/homefree.qcow2 \
    -smp 4 \
    -m 8G \
    -net nic \
    -net user,hostfwd=tcp::2223-:22,hostfwd=tcp::8445-:443,hostfwd=tcp::8885-:80 \
    -netdev bridge,br=hfbr0,id=hn1,helper=$(which qemu-bridge-helper) \
    -device virtio-net,netdev=hn1,mac=e6:c8:ff:09:76:88 \
    &
pids[2]=$!
    # -netdev tap,id=enp1s0,br=hfbr0,helper=$(which qemu-bridge-helper) \
    # -device e1000,netdev=enp1s0,mac=52:53:54:55:56:02 \
sudo -E qemu-kvm \
    -drive file=/var/run/libvirt/nix-ovmf/OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on \
    -drive file=./build/nixos_VARS.fd,if=pflash,format=raw,unit=1 \
    -hda ./build/lan-client.qcow2 \
    -m 2G \
    -netdev bridge,br=hfbr0,id=hn1,helper=$(which qemu-bridge-helper) \
    -device virtio-net,netdev=hn1,mac=e6:c8:ff:09:76:89 \
    &
pids[3]=$!

for pid in ${pids[*]}; do
    wait $pid
done
