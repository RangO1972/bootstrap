#!/bin/bash
set -e

WORKDIR="/opt/stradcs-bootstrap"
CSV="$WORKDIR/interfaces.csv"

echo "### Configuring systemd-networkd interfaces..."

# Pulisci eventuali vecchi file
rm -f /etc/systemd/network/*.network /etc/systemd/network/*.netdev /etc/systemd/network/*.link

# Array per i gruppi
declare -A GROUP_INTERFACES
declare -A GROUP_ROLES
declare -A GROUP_ADDRESSES

while IFS=, read -r original alias role group address; do
  [[ "$original" == "OriginalName" ]] && continue

  # .link
  cat > "/etc/systemd/network/10-${alias}.link" <<EOF
[Match]
OriginalName=${original}

[Link]
Name=${alias}
EOF

  if [[ -z "$group" ]]; then
    # Interfaccia standalone
    if [[ "$role" == "dhcp" ]]; then
      cat > "/etc/systemd/network/20-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
DHCP=yes
EOF
    elif [[ "$role" == "static" ]]; then
      cat > "/etc/systemd/network/20-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
Address=${address}
EOF
    fi
  else
    # Interfaccia parte di un bond
    GROUP_INTERFACES["$group"]+="$alias "
    # La prima interfaccia definisce il tipo di configurazione
    if [[ -z "${GROUP_ROLES[$group]}" ]]; then
      GROUP_ROLES["$group"]="$role"
      GROUP_ADDRESSES["$group"]="$address"
    fi
  fi
done < "$CSV"

# Creazione dei bond
for group in "${!GROUP_INTERFACES[@]}"; do
  members=(${GROUP_INTERFACES[$group]})
  if (( ${#members[@]} < 2 )); then
    echo "Skipping bond $group, only 1 interface."
    continue
  fi

  primary="${members[0]}"
  role="${GROUP_ROLES[$group]}"
  address="${GROUP_ADDRESSES[$group]}"

  echo "Creating bond: $group with members: ${members[*]}"

  # .netdev
  cat > "/etc/systemd/network/10-bond-${group}.netdev" <<EOF
[NetDev]
Name=${group}
Kind=bond

[Bond]
Mode=active-backup
PrimarySlave=${primary}
EOF

  # .network del bond
  if [[ "$role" == "dhcp" ]]; then
    cat > "/etc/systemd/network/20-bond-${group}.network" <<EOF
[Match]
Name=${group}

[Network]
DHCP=yes
EOF
  elif [[ "$role" == "static" ]]; then
    cat > "/etc/systemd/network/20-bond-${group}.network" <<EOF
[Match]
Name=${group}

[Network]
Address=${address}
EOF
  fi

  # .network per ogni slave
  for nic in "${members[@]}"; do
    cat > "/etc/systemd/network/30-${nic}.network" <<EOF
[Match]
Name=${nic}

[Network]
Bond=${group}
EOF
  done
done

echo "### Network configuration complete."
