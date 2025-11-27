#!/bin/bash
set -euo pipefail

trap 'echo "[ERROR] Line $LINENO: \"$BASH_COMMAND\" exited with status $?."' ERR

log() { echo "[INFO]  $1"; }
warn() { echo "[WARN]  $1"; }

echo "-------------------------------------------------------------"
echo "        System Initialization / Template Preparation Script"
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# INPUT DEVICE
# -------------------------------------------------------------
if [[ -e /dev/tty ]]; then
    INPUT_DEV="/dev/tty"
elif [[ -e /dev/console ]]; then
    INPUT_DEV="/dev/console"
else
    INPUT_DEV=""
    warn "No TTY available. Falling back to TEMPLATE mode."
fi

# -------------------------------------------------------------
# HOSTNAME REQUEST (10s timeout)
# -------------------------------------------------------------
NEW_HOSTNAME=""
if [[ -n "$INPUT_DEV" ]]; then
    if read -t 10 -rp "Enter hostname (empty = TEMPLATE mode) [10s]: " NEW_HOSTNAME < "$INPUT_DEV"; then
        :
    else
        echo
        warn "Timeout — TEMPLATE mode selected."
        NEW_HOSTNAME=""
    fi
fi

# -------------------------------------------------------------
# MODE SELECTION
# -------------------------------------------------------------
if [[ -z "$NEW_HOSTNAME" ]]; then
    MODE="TEMPLATE"
    TEMPLATE_HOSTNAME="template"
    log "TEMPLATE MODE"
else
    MODE="CLIENT"
    log "CLIENT MODE — hostname = $NEW_HOSTNAME"
fi

echo

# =================================================================
#                       TEMPLATE MODE
# =================================================================
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Setting hostname: $TEMPLATE_HOSTNAME"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    # update /etc/hosts
    if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
        sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   ${TEMPLATE_HOSTNAME}/" /etc/hosts
    else
        echo "127.0.1.1   ${TEMPLATE_HOSTNAME}" >> /etc/hosts
    fi

    # ------------------------
    # Clean machine IDs
    # ------------------------
    log "Removing machine-id"
    rm -f /etc/machine-id /var/lib/dbus/machine-id

    # ------------------------
    # Clean SSH keys
    # ------------------------
    log "Removing SSH host keys"
    rm -f /etc/ssh/ssh_host_*

    # ------------------------
    # Clean logs and journald
    # ------------------------
    log "Cleaning logs"
    rm -rf /var/log/* /var/tmp/* /tmp/* || true

    # recreate journald dirs (but empty)
    mkdir -p /var/log/journal
    mkdir -p /run/log/journal
    chmod 2755 /var/log/journal /run/log/journal

    # ------------------------
    # Clean APT cache
    # ------------------------
    log "Cleaning APT cache"
    apt clean -y >/dev/null || true

    echo
    echo "-------------------------------------------------------------"
    echo "                       TEMPLATE READY"
    echo "-------------------------------------------------------------"
    echo "hostname      : template"
    echo "machine-id    : REMOVED"
    echo "ssh keys      : REMOVED"
    echo "logs          : CLEANED"
    echo
    echo "Template can now be converted safely."
    echo

    # SHUTDOWN DEFAULT YES
    ANSW="y"
    if [[ -n "$INPUT_DEV" ]]; then
        if read -t 10 -rp "Shutdown now? (Y/n) [10s default=Y]: " ANSW < "$INPUT_DEV"; then
            :
        else
            echo
            warn "Timeout — shutting down."
            ANSW="y"
        fi
    fi

    if [[ "${ANSW,,}" == "y" ]]; then
        log "Shutting down..."
        shutdown -h now
    fi

    exit 0
fi

# =================================================================
#                            CLIENT MODE
# =================================================================

log "Setting hostname: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
    sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi

# machine-id handling
if [[ ! -f /etc/machine-id ]]; then
    log "machine-id missing → generating new one"
    systemd-machine-id-setup
else
    log "machine-id already exists → keeping"
fi

# SSH keys handling
if compgen -G "/etc/ssh/ssh_host_*" > /dev/null; then
    log "SSH host keys already exist → keeping"
else
    log "SSH host keys missing → generating"
    dpkg-reconfigure openssh-server >/dev/null
    systemctl restart ssh || true
fi

log "Cleaning system..."
apt autoremove -y >/dev/null || true
apt clean -y >/dev/null || true
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                     CLIENT INITIALIZED"
echo "-------------------------------------------------------------"
echo "hostname     : $(hostname)"
echo "machine-id   : $(cat /etc/machine-id)"
echo "ssh keys     : OK"
echo
echo

# REBOOT DEFAULT YES
ANSWER="y"
if [[ -n "$INPUT_DEV" ]]; then
    if read -t 10 -rp "Reboot now? (Y/n) [10s default=Y]: " ANSW < "$INPUT_DEV"; then
        :
    else
        echo
        warn "Timeout — rebooting."
        ANSW="y"
    fi
fi

if [[ "${ANSW,,}" == "y" ]]; then
    log "Rebooting..."
    reboot
fi

exit 0
