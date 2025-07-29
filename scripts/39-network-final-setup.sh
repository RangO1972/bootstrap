#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"


log info "Install systemd-resolved..."
apt install -y systemd-resolved

log info "Removing obsolete packages..."
apt-get remove -y ifupdown ifenslave resolvconf rpcbind nfs-common avahi-daemon at || true

log info "Linking resolv.conf to systemd-resolved..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

log info "Enabling systemd services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved

log info "Restarting systemd-networkd and systemd-resolved to apply changes..."
systemctl restart systemd-networkd
systemctl restart systemd-resolved

log info "Triggering udev to apply .link rules..."
udevadm trigger --action=add

