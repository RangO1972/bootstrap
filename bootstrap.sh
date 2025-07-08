#!/bin/bash
set -e

WORKDIR="/opt/stradcs-bootstrap/scripts"

echo "[01-init-vars] Rendo eseguibili tutti gli script..."
find "$WORKDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "### Running bootstrap scripts..."
for script in $(ls $WORKDIR | sort); do
   echo "### Executing $script..."
   bash "$WORKDIR/$script"
done
