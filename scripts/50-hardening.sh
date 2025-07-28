#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

log info "Disabling root SSH login..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh || true

log info "Removing obsolete packages..."
apt-get remove -y ifupdown ifenslave resolvconf rpcbind nfs-common avahi-daemon at || true

log info "Linking resolv.conf to systemd-resolved..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log info "Enabling systemd services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved
