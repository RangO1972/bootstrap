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
# Determine safest input device (TTY-safe)
# -------------------------------------------------------------
if [[ -e /dev/tty ]]; then
    INPUT_DEV="/dev/tty"
elif [[ -e /dev/console ]]; then
    INPUT_DEV="/dev/console"
else
    INPUT_DEV="/dev/null"
    warn "No TTY available — hostname cannot be requested interactively."
fi

# -------------------------------------------------------------
# Ask for hostname
# -------------------------------------------------------------
if [[ "$INPUT_DEV" != "/dev/null" ]]; then
    read -rp "Enter new hostname (leave empty for TEMPLATE mode): " NEW_HOSTNAME < "$INPUT_DEV"
else
    NEW_HOSTNAME=""
fi

if [[ -z "${NEW_HOSTNAME}" ]]; then
    MODE="TEMPLATE"
    RANDOM_SUFFIX=$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    TEMPLATE_HOSTNAME="template-${RANDOM_SUFFIX}"
    log "No hostname provided — entering TEMPLATE mode."
    log "Generated template hostname: ${TEMPLATE_HOSTNAME}"
else
    MODE="CLIENT"
    log "Hostname provided — entering CLIENT mode."
fi

echo

# -------------------------------------------------------------
# TEMPLATE MODE
# -------------------------------------------------------------
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Setting template hostname: ${TEMPLATE_HOSTNAME}"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    if grep -q "^127\.0\.1\.1" /etc/hosts; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1   ${TEMPLATE_HOSTNAME}/" /etc/hosts
    else
        echo "127.0.1.1   ${TEMPLATE_HOSTNAME}" >> /etc/hosts
    fi

    log "Performing light cleanup..."
    apt clean -y >/dev/null || true
    rm -rf /tmp/* /var/tmp/* || true
    journalctl --rotate
    journalctl --vacuum-time=1s

    echo
    echo "-------------------------------------------------------------"
    echo "                   TEMPLATE MODE COMPLETE                     "
    echo "-------------------------------------------------------------"
    echo "Template hostname : ${TEMPLATE_HOSTNAME}"
    echo "SSH keys          : PRESERVED"
    echo "machine-id        : PRESERVED"
    echo
    echo "System is clean and ready to be converted into a TEMPLATE."
    echo
    exit 0
fi

# -------------------------------------------------------------
# CLIENT MODE
# -------------------------------------------------------------
log "Running CLIENT initialization tasks..."

log "Setting hostname to: ${NEW_HOSTNAME}"
hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi

log "Resetting machine-id..."
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup

log "Regenerating SSH host keys..."
rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server >/dev/null
systemctl restart ssh

log "Cleaning APT..."
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true

log "Cleaning logs..."
journalctl --rotate
journalctl --vacuum-time=1s

log "Cleaning temporary files..."
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                  CLIENT INITIALIZATION COMPLETE              "
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "machine-id     : $(cat /etc/machine-id)"
echo "SSH status     : $(systemctl is-active ssh)"
echo
echo "System initialized and ready."
echo "-------------------------------------------------------------"
echo
