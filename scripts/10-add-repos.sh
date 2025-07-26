#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

echo "$TAG - Aggiunta repository Tailscale e Docker..."

# Install tools necessari
apt-get update
apt-get install -y curl ca-certificates gnupg lsb-release

echo "[20-add-repos] Aggiungo repository backports..."
echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" \
    > /etc/apt/sources.list.d/backports.list
    
# === TAILSCALE ===
echo "$TAG - Aggiungo repository Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list >/dev/null

# === DOCKER ===
echo "$TAG - Aggiungo repository Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update finale
echo "$TAG - Eseguo apt update finale..."
apt-get update

echo "$TAG - Installo kernel e header da backports..."
apt-get install -y -t bookworm-backports linux-image-amd64 linux-headers-amd64

echo "$TAG - Repositories aggiunti correttamente."
