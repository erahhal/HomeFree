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
    # Install dependencies
    sudo dnf install -y vim git make qemu-img qemu-kvm libvirt

    if ! command -v nix &> /dev/null; then
        if [ ! -e /nix/var/nix/profiles/system/bin/nix ]; then
            echo "Installing nix..."
            ## This doesn't work without disabling selinux:
            # sh <(curl -L https://nixos.org/nix/install) --daemon

            ## From: https://nix-community.github.io/nix-installers/
            echo "Installing Nix from URL, may take a moment..."
            RPM_URL=https://nix-community.github.io/nix-installers/x86_64/nix-multi-user-2.17.1.rpm
            sudo rpm -i $RPM_URL
        else
            echo "nix is installed but not in your path. log out and log in again."
        fi
    fi

    if [ ! $(getent group nixbld) ]; then
        sudo groupadd nixbld
    fi

    if ! id -nG "$USER" | grep -qw nixbld; then
        sudo usermod -a -G nixbld $USER
        echo "User added to nixbld gropu. log out and back in again."
    fi

    NM_BRIDGE_CONF=/etc/NetworkManager/system-connections/hrbr0.nmconnection
    if [ ! -e $NM_BRIDGE_CONF ]; then
sudo tee $NM_BRIDGE_CONF > /dev/null <<EOF
[connection]
id=hfbr0
# uuid=509b481d-08a5-470d-a47d-eb871336b796
type=bridge
interface-name=hfbr0

[ethernet]

[bridge]

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
EOF
        sudo chmod 600 $BRIDGE_CONFIG
        sudo systemctl restart NetworkManager
    fi

    QEMU_BRIDGE_CONF=/etc/qemu/bridge.conf
    if ! grep -q hfbr0 $QEMU_BRIDGE_CONF; then
        echo "allow hfbr0" | sudo tee -a $QEMU_BRIDGE_CONF
    fi
fi

# Get free space on root partition
FREE=$(df -h | grep "/$" | awk '{ print $4 }')
FREE=${FREE::-1}

if [ $(echo "$FREE < 10" | bc) -ne 0 ] ; then
    echo "WARNING: Free disk space is too low"
fi
