#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"


log info "Aggiunta repository Tailscale e Docker..."

# Install tools necessari
apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release
    
# === TAILSCALE ===
log info "Aggiungo repository Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list >/dev/null

# Update finale
log info "Eseguo apt update finale..."
apt-get update

log info "Repositories aggiunti correttamente."
