#!/bin/bash

set -e

echo "[00-init-system] Updating APT and installing base tools..."

# Primo aggiornamento e installazione pacchetti base essenziali
apt update
apt install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    coreutils \
    lsb-release \
    sudo \
    iproute2 \
    net-tools \
    ethtool

echo "[00-init-system] Base tools installed."
