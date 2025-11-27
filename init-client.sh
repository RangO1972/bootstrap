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
# INPUT DEVICE SELECTION (ALWAYS WORKS IN wget|bash + Serial0)
# -------------------------------------------------------------
if [[ -e /dev/tty ]]; then
    INPUT_DEV="/dev/tty"
elif [[ -e /dev/console ]]; then
    INPUT_DEV="/dev/console"
else
    # no TTY → no prompt → fallback to TEMPLATE
    INPUT_DEV=""
    warn "No TTY available. Falling back to TEMPLATE mode."
fi

# -------------------------------------------------------------
# READ HOSTNAME (TTY-safe)
# -------------------------------------------------------------
NEW_HOSTNAME=""

if [[ -n "$INPUT_DEV" ]]; then
    read -rp "Enter new hostname (leave empty for TEMPLATE mode): " NEW_HOSTNAME < "$INPUT_DEV"
else
    NEW_HOSTNAME=""
fi

# -------------------------------------------------------------
# MODE SELECTION
# -------------------------------------------------------------
if [[ -z "$NEW_HOSTNAME" ]]; then
    MODE="TEMPLATE"

    # generate RANDOM suffix WITHOUT PIPE (no SIGPIPE EVER)
    BYTES=$(dd if=/dev/urandom bs=12 count=1 2>/dev/null | tr -dc 'a-z0-9')
    RANDOM_SUFFIX="${BYTES:0:6}"

    TEMPLATE_HOSTNAME="template-${RANDOM_SUFFIX}"

    log "No hostname provided → TEMPLATE MODE"
    log "Template hostname = ${TEMPLATE_HOSTNAME}"
else
    MODE="CLIENT"
    log "CLIENT MODE → hostname = ${NEW_HOSTNAME}"
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

    log "Light cleanup"
    apt clean -y >/dev/null || true
    rm -rf /tmp/* /var/tmp/* || true
    journalctl --rotate || true
    journalctl --vacuum-time=1s || true

    echo
    echo "-------------------------------------------------------------"
    echo "                   TEMPLATE MODE COMPLETE                     "
    echo "-------------------------------------------------------------"
    echo "Template hostname : ${TEMPLATE_HOSTNAME}"
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
