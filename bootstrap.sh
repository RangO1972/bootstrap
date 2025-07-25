#!/bin/bash
set -e

# Inizializzazione variabili globali
REPO_URL="https://github.com/RangO1972/bootstrap.git"
export WORKDIR="/opt/stradcs-bootstrap"
export INTERFACE_DIR="$WORKDIR/interfaces"
export TARGET_USER="stra"
export NETWORKD_DIR="/etc/systemd/network"
export SCRIPTSDIR="$WORKDIR/scripts"

# Installo git
apt update && apt install -y git

# Clono repository
git clone "$REPO_URL" "$WORKDIR"

echo "[01-init-vars] Imposto permessi nella cartella di lavoro: $WORKDIR"
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

echo "[01-init-vars] Rendo eseguibili tutti gli script..."
find "$SCRIPTSDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "### Running bootstrap scripts..."
for script in $(ls $SCRIPTSDIR | sort); do
   echo "### Executing $script..."
   bash "$SCRIPTSDIR/$script"
done
