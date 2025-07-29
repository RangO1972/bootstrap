#!/bin/bash

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Crea la directory dei log se non esiste
LOGDIR="$WORKDIR/logs"
mkdir -p "$LOGDIR"

# Imposta il file di log con nome del giorno
LOGFILE="$LOGDIR/$(date +%F).log"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    local caller_file

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    caller_file=$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")
    caller_file="${caller_file%.sh}"

    case "$level" in
        info)  color="\033[1;32m[INFO ]\033[0m" ;;
        warn)  color="\033[1;33m[WARN ]\033[0m" ;;
        error) color="\033[1;31m[ERROR]\033[0m" ;;
        *)     color="\033[1;37m[LOG  ]\033[0m" ;;
    esac

    formatted="[$caller_file] $timestamp [$level] $message"

    # Stampa a video
    echo -e "\033[1;37m[${caller_file}]\033[0m $timestamp $color $message"

    # Scrive nel file giornaliero
    echo "$formatted" >> "$LOGFILE"

    # Scrive anche nel journal se disponibile
    if command -v systemd-cat &>/dev/null; then
        echo "$formatted" | systemd-cat -t "$caller_file" -p "${level,,}"
    fi
}
