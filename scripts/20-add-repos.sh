#!/bin/bash
set -e

WORKDIR="/opt/stradcs-bootstrap"
REPOS_FILE="$WORKDIR/repos.sh"

echo "[20-add-repos] Aggiunta repository esterni..."

if [ ! -f "$REPOS_FILE" ]; then
    echo "❌ File repos.sh non trovato in $WORKDIR"
    exit 1
fi

echo "[20-add-repos] Eseguo i comandi dal file repos.sh..."
bash "$REPOS_FILE"

echo "[20-add-repos] Repository aggiunti. Eseguo apt-get update..."
apt-get update

echo "[20-add-repos] Completato."
