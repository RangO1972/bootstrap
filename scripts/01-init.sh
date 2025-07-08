#!/bin/bash
set -e

# Controllo variabili richieste
[ -z "$WORKDIR" ] && echo "WORKDIR non definito" && exit 1
[ -z "$TARGET_USER" ] && echo "TARGET_USER non definito" && exit 1

# Cambio proprietà della cartella e dei suoi contenuti
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

# Rende eseguibili tutti gli script shell
find "$WORKDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "[01-init] Permessi impostati e proprietà assegnata a $TARGET_USER su $WORKDIR"
