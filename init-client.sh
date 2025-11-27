#!/bin/bash
set -euo pipefail

trap 'echo "[ERROR] Line $LINENO: \"$BASH_COMMAND\" exited with status $?."' ERR

log()  { echo "[INFO]  $1"; }
warn() { echo "[WARN]  $1"; }

echo "-------------------------------------------------------------"
echo "        System Initialization / Template Preparation Script"
echo "-------------------------------------------------------------"
echo

# -------------------------------------------------------------
# INPUT DEVICE (TTY-safe)
# -------------------------------------------------------------
if [[ -e /dev/tty ]]; then
    INPUT_DEV="/dev/tty"
elif [[ -e /dev/console ]]; then
    INPUT_DEV="/dev/console"
else
    warn "No TTY available. Falling back to TEMPLATE mode."
    INPUT_DEV=""
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

# ======================================================================
#                           TEMPLATE MODE
# ======================================================================
if [[ "$MODE" == "TEMPLATE" ]]; then

    log "Setting hostname: ${TEMPLATE_HOSTNAME}"
    hostnamectl set-hostname "$TEMPLATE_HOSTNAME"

    # /etc/hosts update
    if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
        sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   template/" /etc/hosts
    else
        echo "127.0.1.1   template" >> /etc/hosts
    fi

    # -------------------------------
    # Machine ID reset (CLOUD-STYLE)
    # -------------------------------
    log "Resetting machine-id (empty file)"
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id

    # -------------------------------
    # SSH KEY removal
    # -------------------------------
    log "Removing SSH host keys"
    rm -f /etc/ssh/ssh_host_*

    # -------------------------------
    # Log cleanup WITHOUT removing dirs
    # -------------------------------
    log "Cleaning logs (preserving directories)"
    find /var/log -type f -delete || true
    rm -rf /tmp/* /var/tmp/* || true

    # journald dirs must exist
    mkdir -p /var/log/journal /run/log/journal
    chmod 2755 /var/log/journal /run/log/journal

    # -------------------------------
    # APT cleanup
    # -------------------------------
    log "Cleaning APT cache"
    apt clean -y >/dev/null || true

    echo
    echo "-------------------------------------------------------------"
    echo "                       TEMPLATE READY"
    echo "-------------------------------------------------------------"
    echo "hostname     : template"
    echo "machine-id   : EMPTY (systemd will regenerate)"
    echo "ssh keys     : REMOVED"
    echo "logs         : CLEANED"
    echo
    echo "Template can now be safely converted."
    echo

    # ---------------------------------------------------------
    # SHUTDOWN WITH TIMEOUT (default YES)
    # ---------------------------------------------------------
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

# ======================================================================
#                                CLIENT MODE
# ======================================================================

log "Setting hostname: $NEW_HOSTNAME"
hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "^127\\.0\\.1\\.1" /etc/hosts; then
    sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1   ${NEW_HOSTNAME}/" /etc/hosts
else
    echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
fi

# -------------------------------------
# MACHINE-ID (generate only if missing)
# -------------------------------------
if [[ ! -s /etc/machine-id ]]; then
    log "machine-id missing → generating"
    systemd-machine-id-setup
else
    log "machine-id exists → keeping"
fi

# -------------------------------------
# SSH KEYS (generate only if missing)
# -------------------------------------
if compgen -G "/etc/ssh/ssh_host_*" > /dev/null; then
    log "SSH keys exist → keeping"
else
    log "SSH keys missing → generating"
    dpkg-reconfigure openssh-server >/dev/null
    systemctl restart ssh || true
fi

log "Performing mild cleanup..."
apt autoremove -y >/dev/null || true
apt clean -y >/dev/null || true
rm -rf /tmp/* /var/tmp/* || true

echo
echo "-------------------------------------------------------------"
echo "                       CLIENT READY"
echo "-------------------------------------------------------------"
echo "hostname     : $(hostname)"
echo "machine-id   : $(cat /etc/machine-id)"
echo "ssh keys     : OK"
echo
echo

# ---------------------------------------------------------
# REBOOT WITH TIMEOUT (default YES)
# ---------------------------------------------------------
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
