#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------
#  Intelligent Initialization Script
#  - TEMPLATE mode (empty hostname)
#  - CLIENT mode  (hostname provided)
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
read -rp "Enter new hostname (leave empty to mark as TEMPLATE): " NEW_HOSTNAME

if [[ -z "${NEW_HOSTNAME}" ]]; then
    MODE="TEMPLATE"
    log "No hostname provided. Switching to TEMPLATE mode."
else
    MODE="CLIENT"
    log "Hostname provided. Switching to CLIENT mode."
fi

echo

# -------------------------------------------------------------
# TEMPLATE MODE
# -------------------------------------------------------------
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Running TEMPLATE preparation tasks..."

    # Light cleanup only — do NOT alter identity
    log "Cleaning APT cache..."
    apt clean -y >/dev/null || true

    log "Cleaning temporary directories..."
    rm -rf /tmp/* /var/tmp/* || true

    log "Light log cleanup..."
    journalctl --rotate
    journalctl --vacuum-time=1s

    echo
    echo "-------------------------------------------------------------"
    echo "                   TEMPLATE PREPARATION DONE                  "
    echo "-------------------------------------------------------------"
    echo "The system has been prepared in TEMPLATE mode:"
    echo " - Hostname unchanged"
    echo " - SSH keys preserved"
    echo " - machine-id preserved"
    echo " - Light cleanup performed"
    echo
    echo "You can now safely convert this machine into a TEMPLATE."
    echo
    exit 0
fi

# -------------------------------------------------------------
# CLIENT MODE (FULL RESET)
# -------------------------------------------------------------
log "Running CLIENT initialization tasks..."

# 1) Set hostname
log "Setting hostname to: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hosts
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
log "Cleaning APT cache..."
apt clean -y >/dev/null || true
apt autoremove -y >/dev/null || true

# 5) Clean logs
log "Cleaning system logs..."
journalctl --rotate
journalctl --vacuum-time=1s

# 6) Clean temp directories
log "Cleaning temp directories..."
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                  CLIENT INITIALIZATION COMPLETE             "
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "machine-id     : $(cat /etc/machine-id)"
echo "SSH status     : $(systemctl is-active ssh)"
echo
echo "The system is now fully initialized and ready for use."
echo "-------------------------------------------------------------"
echo
