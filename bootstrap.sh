#!/bin/bash
set -e

# Inizializzazione variabili globali
REPO_URL="https://github.com/username/repository-name.git"
export WORKDIR="/opt/stradcs-bootstrap"
export INTERFACE_DIR="$WORKDIR/interfaces"
export TARGET_USER="stra"
export NETWORKD_DIR="/etc/systemd/network"
export SCRIPTSDIR="$WORKDIR/scripts"

# Installo git
sudo apt update && sudo apt install -y git

# Clono repository
git clone "$REPO_URL" "$WORKDIR"

echo "[01-init-vars] Imposto permessi nella cartella di lavoro: $WORKDIR"
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

echo "[01-init-vars] Rendo eseguibili tutti gli script..."
find "$SCRIPTSDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "### Running bootstrap scripts..."
for script in $(ls $SCRIPTSDIR | sort); do
   echo "### Executing $script..."
   bash "$WORKDIR/$script"
done
