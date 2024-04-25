#!/usr/bin/env bash

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

if [ "$OS" == "Fedora Linux" ]; then
    OVMF_NVRAM=/usr/share/OVMF/OVMF_VARS.fd
    OVMF_CODE=/usr/share/OVMF/OVMF_CODE.fd
    VIRTIOFSD=/usr/libexec/virtiofsd
    QEMU_BRIDGE_HELPER=/usr/libexec/qemu-bridge-helper
elif [ "$OS" == "NixOS" ]; then
    OVMF_PATH=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes eval -f '<nixpkgs>' --raw "OVMF.fd")
    OVMF_NVRAM=$OVMF_PATH/FV/OVMF_VARS.fd
    OVMF_CODE=$OVMF_PATH/FV/OVMF_CODE.fd
    VIRTIOFSD=$(which virtiofsd)
    QEMU_BRIDGE_HELPER=$(which qemu-bridge-helper)
else
    echo "Unsupported OS";
    exit 1
fi

if [ x$DISPLAY != x ] ; then
    GUI_FLAG=
else
    GUI_FLAG=-nographic
fi

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
sudo cp $OVMF_NVRAM ./build/OVMF_VARS.fd
sudo chown $USER:users ./build/OVMF_VARS.fd
# @TODO: What if virtiofsd is already running elsewhere? Can it be run as a service?
sudo $VIRTIOFSD --socket-path /tmp/vhostqemu --shared-dir ./ --cache auto &
pids[1]=$!
    # -netdev tap,id=enp1s0,br=hfbr0,helper=$QEMU_BRIDGE_HELPER \
    # -device e1000,netdev=enp1s0,mac=52:53:54:55:56:01 \

# Port 8123: Home Assistant
# Port 9000: Authentik
sudo -E qemu-kvm \
    $GUI_FLAG \
    -cpu host \
    -enable-kvm \
    -chardev socket,id=char0,path=/tmp/vhostqemu \
    -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=mount_homefree_source \
    -object memory-backend-file,id=mem,size=8G,mem-path=/dev/shm,share=on \
    -numa node,memdev=mem \
    -drive file=$OVMF_CODE,if=pflash,format=raw,unit=0,readonly=on \
    -drive file=./build/OVMF_VARS.fd,if=pflash,format=raw,unit=1 \
    -hda ./build/homefree.qcow2 \
    -smp 4 \
    -m 8G \
    -net nic \
    -net user,hostfwd=tcp::2223-:22,hostfwd=tcp::8445-:443,hostfwd=tcp::8885-:80,hostfwd=tcp::8123-:8123,hostfwd=tcp::9000-:9000 \
    -netdev bridge,br=hfbr0,id=hn1,helper=$QEMU_BRIDGE_HELPER \
    -device virtio-net,netdev=hn1,mac=e6:c8:ff:09:76:88 \
    &
pids[2]=$!
    # -netdev tap,id=enp1s0,br=hfbr0,helper=$QEMU_BRIDGE_HELPER \
    # -device e1000,netdev=enp1s0,mac=52:53:54:55:56:02 \
sudo -E qemu-kvm \
    $GUI_FLAG \
    -cpu host \
    -enable-kvm \
    -drive file=$OVMF_CODE,if=pflash,format=raw,unit=0,readonly=on \
    -drive file=./build/OVMF_VARS.fd,if=pflash,format=raw,unit=1 \
    -hda ./build/lan-client.qcow2 \
    -m 2G \
    -netdev bridge,br=hfbr0,id=hn1,helper=$QEMU_BRIDGE_HELPER \
    -device virtio-net,netdev=hn1,mac=e6:c8:ff:09:76:89 \
    &
pids[3]=$!

for pid in ${pids[*]}; do
    wait $pid
done
