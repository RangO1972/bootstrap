#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"


log info "Aggiunta repository"

# Install tools necessari
apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release


# === TAILSCALE ===
log info "Aggiungo repository Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list >/dev/null

# === backports ===
log info "Add backports repository"
FILE="/etc/apt/sources.list.d/bookworm-backports.list"
ENTRY="deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware"
grep -qxF "$ENTRY" "$FILE" 2>/dev/null || echo "$ENTRY" > "$FILE"

# Aggiungi il pinning per il kernel  e podman dai backports
PIN_FILE="/etc/apt/preferences.d/kernel-backports"
if [[ ! -f "$PIN_FILE" ]]; then
  cat <<EOF > "$PIN_FILE"
Package: linux-image-amd64
Pin: release a=bookworm-backports
Pin-Priority: 990

Package: podman
Pin: release a=bookworm-backports
Pin-Priority: 990

EOF
fi

# Update finale
log info "Eseguo apt update finale..."
apt-get update

log info "Repositories aggiunti correttamente."
