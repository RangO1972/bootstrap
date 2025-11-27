#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------
#  Client Initialization Script
#  - Sets a new hostname
#  - Regenerates SSH host keys
#  - Restarts SSH service
#  - Provides a clean summary
# -------------------------------------------------------------

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

echo "-------------------------------------------------------------"
echo "                 Client Initialization Script                 "
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# 1) Set Hostname
# -------------------------------------------------------------
read -rp "Enter the new hostname for this machine: " NEW_HOSTNAME

if [[ -z "$NEW_HOSTNAME" ]]; then
    error "Hostname cannot be empty."
fi

log "Setting hostname to: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hosts
if grep -q "127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi

log "Hostname updated successfully."
echo

# -------------------------------------------------------------
# 2) Regenerate SSH Host Keys
# -------------------------------------------------------------
log "Regenerating SSH host keys..."

# Remove existing host keys (template usually has none)
rm -f /etc/ssh/ssh_host_*

# Regenerate
dpkg-reconfigure openssh-server >/dev/null

# Restart SSH service
systemctl restart ssh

log "SSH host keys regenerated and SSH service restarted."
echo

# -------------------------------------------------------------
# 3) Summary
# -------------------------------------------------------------
echo "-------------------------------------------------------------"
echo "                     Initialization Complete                  "
echo "-------------------------------------------------------------"
echo "Hostname       : $(hostname)"
echo "SSH Service    : $(systemctl is-active ssh)"
echo
echo "The machine is now properly initialized and ready for use."
echo "You may now connect via SSH using the new hostname."
echo
