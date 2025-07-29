#!/bin/bash

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Crea la directory dei log se non esiste
LOGDIR="$WORKDIR/logs"
mkdir -p "$LOGDIR"

# Imposta il file di log con nome del giorno (es: 2025-07-30.log)
LOGFILE="$LOGDIR/$(date +%F).log"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    local caller_file
    local journal_level

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    caller_file=$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")
    caller_file="${caller_file%.sh}"

    case "$level" in
        info)    color="\033[1;32m[INFO ]\033[0m"; journal_level="info" ;;
        warn)    color="\033[1;33m[WARN ]\033[0m"; journal_level="warning" ;;
        error)   color="\033[1;31m[ERROR]\033[0m"; journal_level="err" ;;
        debug)   color="\033[1;34m[DEBUG]\033[0m"; journal_level="debug" ;;
        notice)  color="\033[1;36m[NOTICE]\033[0m"; journal_level="notice" ;;
        *)       color="\033[1;37m[LOG  ]\033[0m"; journal_level="info" ;;
    esac

    # Formato stampato e loggato
    formatted="$timestamp [$level] [$caller_file] $message"

    # Output a video
    echo -e "$timestamp $color \033[1;37m[${caller_file}]\033[0m $message"

    # Scrive anche su file
    echo "$formatted" >> "$LOGFILE"

    # Invia a systemd-journal (se disponibile)
    if command -v systemd-cat &>/dev/null; then
        echo "$formatted" | systemd-cat -t "stradcs-bootstrap" -p "$journal_level"
    fi
}
