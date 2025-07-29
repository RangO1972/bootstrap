#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"


# === TAILSCALE ===

log info "Add Tailscale repository..."
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list >/dev/null

apt-get update
log info "Install Tailscale..."
apt-get install tailscale -y

