#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

# Controllo variabili richieste
[ -z "$WORKDIR" ] && echo "WORKDIR non definito" && exit 1
[ -z "$TARGET_USER" ] && echo "TARGET_USER non definito" && exit 1

# Cambio proprietà della cartella e dei suoi contenuti
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

# Rende eseguibili tutti gli script shell
find "$WORKDIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "$TAG - Permessi impostati e proprietà assegnata a $TARGET_USER su $WORKDIR"
