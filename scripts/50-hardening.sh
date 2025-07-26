#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

echo "$TAG - Disabling root SSH login..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh || true

echo "$TAG - Removing obsolete packages..."
apt-get remove -y ifupdown ifenslave resolvconf rpcbind nfs-common avahi-daemon at || true

echo "$TAG - Linking resolv.conf to systemd-resolved..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "$TAG - Enabling systemd services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved
