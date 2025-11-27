#!/bin/bash
set -euo pipefail

trap 'echo "[ERROR] Line $LINENO: \"$BASH_COMMAND\" exited with status $?."' ERR

log()   { echo "[INFO]  $1"; }
warn()  { echo "[WARN]  $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

echo "-------------------------------------------------------------"
echo "        Intelligent System Initialization / Reset Script"
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# INPUT DEVICE SELECTION (TTY-safe)
# -------------------------------------------------------------
if [[ -e /dev/tty ]]; then
    INPUT_DEV="/dev/tty"
elif [[ -e /dev/console ]]; then
    INPUT_DEV="/dev/console"
else
    INPUT_DEV=""
    warn "No TTY available. Automatic TEMPLATE mode."
fi

# -------------------------------------------------------------
# HOSTNAME REQUEST (timeout 10s)
# -------------------------------------------------------------
NEW_HOSTNAME=""

if [[ -n "$INPUT_DEV" ]]; then
    if read -t 10 -rp "Enter new hostname (empty = TEMPLATE mode) [10s]: " NEW_HOSTNAME < "$INPUT_DEV"; then
        :
    else
        echo
        warn "Timeout — switching to TEMPLATE mode."
        NEW_HOSTNAME=""
    fi
else
    NEW_HOSTNAME=""
fi

# -------------------------------------------------------------
# MODE SELECTION
# -------------------------------------------------------------
if [[ -z "$NEW_HOSTNAME" ]]; then
    MODE="TEMPLATE"
    TEMPLATE_HOSTNAME="template"
    log "TEMPLATE MODE selected."
else
    MODE="CLIENT"
    log "CLIENT MODE — hostname = $NEW_HOSTNAME"
fi

echo

# -------------------------------------------------------------
# TEMPLATE MODE
# -------------------------------------------------------------
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Applying template hostname: ${TEMPLATE_HOSTNAME}"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
        sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   ${TEMPLATE_HOSTNAME}/" /etc/hosts
    else
        echo "127.0.1.1   ${TEMPLATE_HOSTNAME}" >> /etc/hosts
    fi

    log "Performing light cleanup..."
    apt clean -y >/dev/null || true
    rm -rf /tmp/* /var/tmp/* || true
    journalctl --rotate || true
    journalctl --vacuum-time=1s || true

    echo
    echo "-------------------------------------------------------------"
    echo "                   TEMPLATE MODE COMPLETE"
    echo "-------------------------------------------------------------"
    echo "Template hostname : template"
    echo "SSH keys          : PRESERVED"
    echo "machine-id        : PRESERVED"
    echo

    # Ask for shutdown (default YES, timeout 10s)
    ANSW="y"

    if [[ -n "$INPUT_DEV" ]]; then
        if read -t 10 -rp "Shutdown now? (Y/n) [default=Y, 10s]: " ANSW < "$INPUT_DEV"; then
            :
        else
            echo
            warn "Timeout — performing default shutdown."
            ANSW="y"
        fi
    fi

    if [[ "${ANSW,,}" == "y" ]]; then
        log "Shutting down..."
        shutdown -h now
    fi

    exit 0
fi

# -------------------------------------------------------------
# CLIENT MODE
# -------------------------------------------------------------
log "Setting hostname: ${NEW_HOSTNAME}"
hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
    sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi

log "Resetting machine-id..."
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup

log "Regenerating SSH host keys..."
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server >/dev/null
systemctl restart ssh || true

log "Cleaning system..."
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true
journalctl --rotate || true
journalctl --vacuum-time=1s || true
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                  CLIENT INITIALIZATION COMPLETE"
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "machine-id     : $(cat /etc/machine-id)"
echo "SSH status     : $(systemctl is-active ssh)"
echo

# Ask for reboot (default YES, timeout 10s)
ANSWER="y"

if [[ -n "$INPUT_DEV" ]]; then
    if read -t 10 -rp "Reboot now? (Y/n) [default=Y, 10s]: " ANSW < "$INPUT_DEV"; then
        :
    else
        echo
        warn "Timeout — performing default reboot."
        ANSW="y"
    fi
fi

if [[ "${ANSW,,}" == "y" ]]; then
    log "Rebooting..."
    reboot
fi

exit 0
