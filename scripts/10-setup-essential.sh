#!/bin/bash
set -e

echo "[10-setup-essential] Aggiornamento pacchetti..."
apt-get update

echo "[10-setup-essential] Installazione pacchetti minimi essenziali..."
apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    git \
    sudo \
    systemd-networkd \
    systemd-resolved

echo "[10-setup-essential] Abilitazione e attivazione systemd-networkd e resolved..."
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl start systemd-networkd.service
systemctl start systemd-resolved.service

echo "[10-setup-essential] Verifica completata."
