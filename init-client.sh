#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------
#  Intelligent Initialization Script (Template / Client)
#  TTY-SAFE VERSION (works with wget|bash)
# -------------------------------------------------------------

log()   { echo "[INFO]  $1"; }
warn()  { echo "[WARN]  $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

echo "-------------------------------------------------------------"
echo "        Intelligent System Initialization / Reset Script      "
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# 1) Ask for hostname (using TTY only)
# -------------------------------------------------------------
read -rp "Enter new hostname (leave empty for TEMPLATE mode): " NEW_HOSTNAME < /dev/tty

if [[ -z "${NEW_HOSTNAME}" ]]; then
    MODE="TEMPLATE"

    # Generate safe template-specific hostname
    RANDOM_SUFFIX=$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    TEMPLATE_HOSTNAME="template-${RANDOM_SUFFIX}"

    log "No hostname provided → entering TEMPLATE mode."
    log "Generated template hostname: ${TEMPLATE_HOSTNAME}"
else
    MODE="CLIENT"
    log "Hostname provided → entering CLIENT mode."
fi

echo

# -------------------------------------------------------------
# TEMPLATE MODE
# -------------------------------------------------------------
if [[ "$MODE" == "TEMPLATE" ]]; then

    # Hostname setup
    log "Setting template hostname: ${TEMPLATE_HOSTNAME}"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    if grep -q "^127\.0\.1\.1" /etc/hosts; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1   ${TEMPLATE_HOSTNAME}/" /etc/hosts
    else
        echo "127.0.1.1   ${TEMPLATE_HOSTNAME}" >> /etc/hosts
    fi
    log "Template hostname applied."

    # Light cleanup (keep identity intact)
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
    echo "The system is now clean and ready to be converted into a TEMPLATE."
    echo
    exit 0
fi

# -------------------------------------------------------------
# CLIENT MODE
# -------------------------------------------------------------
log "Running CLIENT initialization tasks..."

# 1) Hostname
log "Setting hostname to: ${NEW_HOSTNAME}"
hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi
log "Hostname updated."

# 2) Reset machine-id
log "Resetting machine-id..."
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup
log "machine-id regenerated."

# 3) Remove and regenerate SSH keys
log "Removing old SSH host keys..."
rm -f /etc/ssh/ssh_host_*

log "Generating new SSH host keys..."
dpkg-reconfigure openssh-server >/dev/null

systemctl restart ssh
log "SSH restarted with fresh keys."

# 4) APT cleanup
log "Cleaning APT..."
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true

# 5) Log cleanup
log "Cleaning logs..."
journalctl --rotate
journalctl --vacuum-time=1s

# 6) Temp cleanup
log "Cleaning temporary directories..."
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                  CLIENT INITIALIZATION COMPLETE              "
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "machine-id     : $(cat /etc/machine-id)"
echo "SSH status     : $(systemctl is-active ssh)"
echo
echo "The system is now fully initialized and ready for use."
echo "-------------------------------------------------------------"
echo
