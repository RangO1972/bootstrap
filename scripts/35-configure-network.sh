#!/bin/bash
set -e

echo "### Configuring systemd-networkd interfaces..."

CSV_FILE="/opt/stradcs-bootstrap/interfaces.csv"
NETWORK_DIR="/etc/systemd/network"

mkdir -p "$NETWORK_DIR"

# Traccia delle interfacce già assegnate
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

# Legge il file CSV saltando la prima riga
tail -n +2 "$CSV_FILE" | while IFS=',' read -r original alias role group; do
  original=$(echo "$original" | xargs)
  alias=$(echo "$alias" | xargs)
  role=$(echo "$role" | xargs | tr '[:upper:]' '[:lower:]')
  group=$(echo "$group" | xargs)

  [[ -z "$alias" ]] && continue

  if [[ "$original" == "<AUTO>" ]]; then
    original=$(get_first_unused_nic)
    echo ">> Assigned '$original' to alias '$alias'"
  fi

  # Crea file .link
  cat > "$NETWORK_DIR/10-${alias}.link" <<EOF
[Match]
OriginalName=$original

[Link]
Name=$alias
EOF

  # Crea file .network
  case "$role" in
    dhcp)
      cat > "$NETWORK_DIR/10-${alias}.network" <<EOF
[Match]
Name=$alias

[Network]
DHCP=yes
EOF
      ;;
    static)
      cat > "$NETWORK_DIR/10-${alias}.network" <<EOF
[Match]
Name=$alias

[Network]
Address=__REPLACE_ME__
EOF
      ;;
    ignore)
      echo "# Skipping $alias (ignored)" ;;
    *)
      echo "!! Unknown role '$role' for $alias, skipping..." ;;
  esac
done

echo "### Network configuration complete."
