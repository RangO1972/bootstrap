#!/bin/bash

set -e

# Inizializzazione variabili globali
export WORKDIR="/opt/stradcs-bootstrap"
export INTERFACE_DIR="$WORKDIR/interfaces"
export TARGET_USER="stra"
export NETWORKD_DIR="/etc/systemd/network"

echo "[01-init-vars] Imposto permessi nella cartella di lavoro: $WORKDIR"
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

echo "[01-init-vars] Rendo eseguibili tutti gli script..."
find "$WORKDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "[01-init-vars] Inizializzazione completata."
