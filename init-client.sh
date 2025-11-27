#!/bin/bash
set -euo pipefail

trap 'echo "[ERROR] Line $LINENO: \"$BASH_COMMAND\" exited with status $?."' ERR

log()   { echo "[INFO]  $1"; }
warn()  { echo "[WARN]  $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

echo "-------------------------------------------------------------"
echo "        Intelligent System Initialization / Reset Script      "
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
    warn "No TTY available. Falling back to TEMPLATE mode."
fi

# -------------------------------------------------------------
# READ HOSTNAME
# -------------------------------------------------------------
NEW_HOSTNAME=""

if [[ -n "$INPUT_DEV" ]]; then
    read -rp "Enter new hostname (leave empty for TEMPLATE mode): " NEW_HOSTNAME < "$INPUT_DEV"
else
    NEW_HOSTNAME=""
fi

# -------------------------------------------------------------
# MODE
# -------------------------------------------------------------
if [[ -z "$NEW_HOSTNAME" ]]; then
    MODE="TEMPLATE"
    TEMPLATE_HOSTNAME="template"
    log "TEMPLATE MODE → hostname = template"
else
    MODE="CLIENT"
    log "CLIENT MODE → hostname = $NEW_HOSTNAME"
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

    log "Light cleanup..."
    apt clean -y >/dev/null || true
    rm -rf /tmp/* /var/tmp/* || true
    journalctl --rotate || true
    journalctl --vacuum-time=1s || true

    echo
    echo "-------------------------------------------------------------"
    echo "                   TEMPLATE MODE COMPLETE                     "
    echo "-------------------------------------------------------------"
    echo "Template hostname : template"
    echo "SSH keys          : PRESERVED"
    echo "machine-id        : PRESERVED"
    echo
    echo "System is ready for template conversion."
    echo
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

log "Resetting machine-id"
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup

log "Regenerating SSH host keys"
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server >/dev/null
systemctl restart ssh || true

log "Cleaning system"
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true
journalctl --rotate || true
journalctl --vacuum-time=1s || true
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                  CLIENT INITIALIZATION COMPLETE              "
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "machine-id     : $(cat /etc/machine-id)"
echo "SSH status     : $(systemctl is-active ssh)"
echo
echo "Client ready."
echo "-------------------------------------------------------------"
echo
