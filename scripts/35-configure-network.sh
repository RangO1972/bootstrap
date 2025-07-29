#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

log info "Configuring systemd-networkd interfaces..."

CSV_FILE="$WORKDIR/interfaces.csv"
NETWORK_DIR="/etc/systemd/network"

mkdir -p "$NETWORK_DIR"
log info "Created/verified network configuration directory: $NETWORK_DIR"

USED_NICS=()

get_first_unused_nic() {
  for nic in $(ls /sys/class/net); do
    [[ "$nic" == "lo" ]] && continue
    [[ " ${USED_NICS[*]} " =~ " $nic " ]] && continue
    USED_NICS+=("$nic")
    echo "$nic"
    return
  done
}

log info "Reading configuration from CSV: $CSV_FILE"
tail -n +2 "$CSV_FILE" | while IFS=',' read -r original alias role group address; do
  original=$(echo "$original" | xargs)
  alias=$(echo "$alias" | xargs)
  role=$(echo "$role" | xargs | tr '[:upper:]' '[:lower:]')
  group=$(echo "$group" | xargs)
  address=$(echo "$address" | xargs)

  if [[ -z "$alias" ]]; then
    log warn "Skipping line with empty alias."
    continue
  fi

  if [[ "$original" == "<AUTO>" ]]; then
    original=$(get_first_unused_nic)
    log info "Auto-assigned NIC '$original' to alias '$alias'"
  fi

  # Creazione file .link
  LINK_FILE="$NETWORK_DIR/10-${alias}.link"
  log info "Creating .link file for '$alias' (original: '$original')"
  cat > "$LINK_FILE" <<EOF
[Match]
OriginalName=$original

[Link]
Name=$alias
EOF

  NETWORK_FILE="$NETWORK_DIR/10-${alias}.network"
  case "$role" in
    dhcp)
      log info "Configuring DHCP for '$alias'"
      cat > "$NETWORK_FILE" <<EOF
[Match]
Name=$alias

[Network]
DHCP=yes
EOF
      ;;
    static)
      if [[ -z "$address" || "$address" == "__REPLACE_ME__" ]]; then
        log warn "No valid address provided for static role on '$alias', placeholder inserted."
        address="__REPLACE_ME__"
      fi
      log info "Configuring STATIC IP for '$alias' → $address"
      cat > "$NETWORK_FILE" <<EOF
[Match]
Name=$alias

[Network]
Address=$address
EOF
      ;;
    ignore)
      log info "Ignoring '$alias' as per configuration"
      ;;
    *)
      log warn "Unknown role '$role' for alias '$alias', skipping interface"
      ;;
  esac
done

log info "Network interface configuration completed successfully."

