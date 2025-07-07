#!/bin/bash
set -e

echo "### Disabling root SSH login..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh || true

echo "### Removing obsolete packages..."
apt-get remove -y ifupdown ifenslave resolvconf rpcbind nfs-common avahi-daemon at || true

echo "### Linking resolv.conf to systemd-resolved..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "### Enabling systemd services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved
