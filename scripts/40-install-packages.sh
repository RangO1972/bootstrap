#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

log info "Updating package lists..."
apt-get update

log info "Installing kernel & header..."
apt-get install -y -t bookworm-backports linux-image-amd64 linux-headers-amd64

log info "Installing packages..."
apt-get install -y $(cat /opt/stradcs-bootstrap/configs/packages.txt)

apt autoremove -y

