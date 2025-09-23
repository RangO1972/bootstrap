#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

log info "Updating package lists..."
apt-get update

log info "Installing packages..."
apt-get install -y $(cat /opt/stradcs-bootstrap/configs/packages.txt)

apt autoremove --purge -y
apt clean
