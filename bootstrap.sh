#!/bin/bash
set -e

BASEURL="https://raw.githubusercontent.com/RangO1972/bootstrap/main"
WORKDIR="/opt/stradcs/bootstrap"

echo "### Creating working directory $WORKDIR..."
mkdir -p "$WORKDIR"

echo "### Downloading supporting files from $BASEURL..."
curl -fsSL "$BASEURL/repos.sh" -o "$WORKDIR/repos.sh"
curl -fsSL "$BASEURL/packages.txt" -o "$WORKDIR/packages.txt"
curl -fsSL "$BASEURL/interfaces.csv" -o "$WORKDIR/interfaces.csv"
curl -fsSL "$BASEURL/nftables.conf" -o "$WORKDIR/nftables.conf"

chmod +x "$WORKDIR/repos.sh"

echo "### Running repository setup..."
bash "$WORKDIR/repos.sh"

echo "### Updating package lists..."
apt-get update

echo "### Installing all packages..."
apt-get install -y $(cat "$WORKDIR/packages.txt")

echo "### Creating user stra..."
useradd -m -s /bin/bash stra
echo "Set password for stra manually with: passwd stra"

usermod -aG sudo stra
usermod -aG docker stra

echo "### Disabling root SSH login..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh || true

echo "### Removing obsolete packages..."
apt-get remove -y ifupdown ifenslave resolvconf rpcbind nfs-common avahi-daemon at || true

echo "### Linking /etc/resolv.conf to systemd-resolved..."
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "### Enabling systemd services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# Prepara array per gruppi
FIELD_NICS=()
UPSTREAM_NICS=()

echo "### Creating .link files and collecting interfaces..."
while IFS=, read -r original alias role group; do
  # Skip header
  [[ "$original" == "OriginalName" ]] && continue

  # Crea il .link
  cat > "/etc/systemd/network/10-${alias}.link" <<EOF
[Match]
OriginalName=${original}

[Link]
Name=${alias}
EOF

  # Conta i gruppi
  case "$group" in
    field)
      FIELD_NICS+=("$alias")
      ;;
    upstream)
      UPSTREAM_NICS+=("$alias")
      ;;
  esac

  # Config standalone DHCP/STATIC
  if [[ "$role" == "dhcp" ]]; then
    cat > "/etc/systemd/network/20-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
DHCP=yes
EOF
  elif [[ "$role" == "static" ]]; then
    # IP predefinito per static
    if [[ "$alias" == "mgnt" ]]; then
      IPADDR="192.168.120.10/24"
    elif [[ "$alias" == "fielda" ]]; then
      IPADDR="192.168.130.10/24"
    elif [[ "$alias" == "upstrma" ]]; then
      IPADDR="192.168.140.10/24"
    else
      IPADDR="192.168.200.10/24"
    fi

    cat > "/etc/systemd/network/20-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
Address=${IPADDR}
EOF
  fi

done < "$WORKDIR/interfaces.csv"

### FIELD bonding o standalone
if (( ${#FIELD_NICS[@]} > 1 )); then
  echo "### Configuring bonding for FIELD"
  cat > /etc/systemd/network/10-bond-field.netdev <<EOF
[NetDev]
Name=field
Kind=bond

[Bond]
Mode=active-backup
PrimarySlave=${FIELD_NICS[0]}
EOF

  cat > /etc/systemd/network/20-bond-field.network <<EOF
[Match]
Name=field

[Network]
Address=192.168.130.10/24
EOF

  for nic in "${FIELD_NICS[@]}"; do
    cat > "/etc/systemd/network/30-${nic}.network" <<EOF
[Match]
Name=${nic}

[Network]
Bond=field
EOF
  done

elif (( ${#FIELD_NICS[@]} == 1 )); then
  echo "### Configuring FIELD as standalone"
  cat > "/etc/systemd/network/20-${FIELD_NICS[0]}.network" <<EOF
[Match]
Name=${FIELD_NICS[0]}

[Network]
Address=192.168.130.10/24
EOF
fi

### UPSTREAM bonding o standalone
if (( ${#UPSTREAM_NICS[@]} > 1 )); then
  echo "### Configuring bonding for UPSTREAM"
  cat > /etc/systemd/network/11-bond-upstream.netdev <<EOF
[NetDev]
Name=upstream
Kind=bond

[Bond]
Mode=active-backup
PrimarySlave=${UPSTREAM_NICS[0]}
EOF

  cat > /etc/systemd/network/21-bond-upstream.network <<EOF
[Match]
Name=upstream

[Network]
Address=192.168.140.10/24
EOF

  for nic in "${UPSTREAM_NICS[@]}"; do
    cat > "/etc/systemd/network/31-${nic}.network" <<EOF
[Match]
Name=${nic}

[Network]
Bond=upstream
EOF
  done

elif (( ${#UPSTREAM_NICS[@]} == 1 )); then
  echo "### Configuring UPSTREAM as standalone"
  cat > "/etc/systemd/network/21-${UPSTREAM_NICS[0]}.network" <<EOF
[Match]
Name=${UPSTREAM_NICS[0]}

[Network]
Address=192.168.140.10/24
EOF
fi

echo "### Installing nftables config..."
cp "$WORKDIR/nftables.conf" /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

echo "### Rebooting in 5 seconds..."
sleep 5
reboot
