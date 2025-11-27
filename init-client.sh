#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------
#  Intelligent Initialization Script (Template / Client)
# -------------------------------------------------------------

log()   { echo "[INFO]  $1"; }
warn()  { echo "[WARN]  $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

echo "-------------------------------------------------------------"
echo "        Intelligent System Initialization / Reset Script      "
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# 1) Ask for hostname
# -------------------------------------------------------------
read -rp "Enter new hostname (leave empty for TEMPLATE mode): " NEW_HOSTNAME

if [[ -z "${NEW_HOSTNAME}" ]]; then
    MODE="TEMPLATE"
    # Generate template hostname
    # Example: template-abc123
    RANDOM_SUFFIX=$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    TEMPLATE_HOSTNAME="template-${RANDOM_SUFFIX}"

    log "No hostname provided. Switching to TEMPLATE mode."
    log "Generated template hostname: ${TEMPLATE_HOSTNAME}"
else
    MODE="CLIENT"
    log "Hostname provided. Switching to CLIENT mode."
fi

echo

# -------------------------------------------------------------
# TEMPLATE MODE
# -------------------------------------------------------------
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Setting template hostname: ${TEMPLATE_HOSTNAME}"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    # Update /etc/hosts
    if grep -q "^127\.0\.1\.1" /etc/hosts; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1   ${TEMPLATE_HOSTNAME}/" /etc/hosts
    else
        echo "127.0.1.1   ${TEMPLATE_HOSTNAME}" >> /etc/hosts
    fi

    log "Hostname updated for template."

    # Light cleanup (identity preserved)
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
    echo "SSH keys          : preserved (not regenerated)"
    echo "machine-id        : preserved"
    echo
    echo "The system is now ready to be converted into a TEMPLATE."
    echo
    exit 0
fi

# -------------------------------------------------------------
# CLIENT MODE
# -------------------------------------------------------------
log "Running CLIENT initialization tasks..."

# 1) Set hostname
log "Setting hostname to: $NEW_HOSTNAME"
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

# 4) Clean APT
log "Cleaning APT..."
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true

# 5) Clean logs
log "Cleaning logs..."
journalctl --rotate
journalctl --vacuum-time=1s

# 6) Clean temp
log "Cleaning temp directories..."
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
echo
