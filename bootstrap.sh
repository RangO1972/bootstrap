#!/bin/bash
set -e

# Imposta WORKDIR assoluto (fisso)
export WORKDIR="/opt/stradcs-bootstrap"

# Altre variabili globali
export REPO_URL="https://github.com/RangO1972/bootstrap.git"
export INTERFACE_DIR="$WORKDIR/interfaces"
export TARGET_USER="stra"
export NETWORKD_DIR="/etc/systemd/network"
export SCRIPTSDIR="$WORKDIR/scripts"

echo "Inizio bootstrap da $WORKDIR"

# Installa Git se non esiste
if ! command -v git &>/dev/null; then
    echo "Git non trovato. Installo git..."
    apt update && apt install -y git
else
    echo "Git già installato"
fi

# Clona repo se necessario
if [ ! -d "$WORKDIR/.git" ]; then
    echo "Clono il repository da $REPO_URL"
    git clone "$REPO_URL" "$WORKDIR"
else
    echo "Repository già presente in $WORKDIR. Salto il clone."
fi
# Includi funzioni comuni
source "$WORKDIR/lib/common.sh"

# Permessi e chmod
log info "Imposto permessi nella cartella di lavoro: $WORKDIR"
chown -R "$TARGET_USER:$TARGET_USER" "$WORKDIR"

log info "Rendo eseguibili tutti gli script in $SCRIPTSDIR"
find "$SCRIPTSDIR" -type f -name "*.sh" -exec chmod +x {} \;

# Esecuzione ordinata degli script
log info "Avvio degli script in $SCRIPTSDIR"
for script in $(ls "$SCRIPTSDIR" | sort); do
    log info "Eseguo $script..."
    bash "$SCRIPTSDIR/$script"
done

log info "Bootstrap completato"
