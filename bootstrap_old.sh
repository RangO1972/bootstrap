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
if id "stra" &>/dev/null; then
  echo "User stra already exists, skipping creation."
else
  echo "### Creating user stra..."
  useradd -m -s /bin/bash stra
  echo "Set password for stra manually with: passwd stra"
fi

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

echo "### Creating .link files and bonding configs..."
while IFS=, read -r original alias; do
  # .link file
  cat > "/etc/systemd/network/10-${alias}.link" <<EOF
[Match]
OriginalName=${original}

[Link]
Name=${alias}
EOF

  # If it's a bond slave, create the slave .network
  if [[ "$alias" == "fielda" || "$alias" == "fieldb" ]]; then
    bondname="field"
    cat > "/etc/systemd/network/30-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
Bond=${bondname}
EOF
  elif [[ "$alias" == "upstrma" || "$alias" == "upstrmb" ]]; then
    bondname="upstream"
    cat > "/etc/systemd/network/30-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
Bond=${bondname}
EOF
  elif [[ "$alias" == "dmz" ]]; then
    cat > "/etc/systemd/network/20-${alias}.network" <<EOF
[Match]
Name=${alias}

[Network]
DHCP=yes
EOF
  fi
done < "$WORKDIR/interfaces.csv"

# Bond NetDev configs
cat > /etc/systemd/network/10-bond-field.netdev <<EOF
[NetDev]
Name=field
Kind=bond

[Bond]
Mode=active-backup
PrimarySlave=fielda
EOF

cat > /etc/systemd/network/11-bond-upstream.netdev <<EOF
[NetDev]
Name=upstream
Kind=bond

[Bond]
Mode=active-backup
PrimarySlave=upstrma
EOF

# Bond .network configs
cat > /etc/systemd/network/20-bond-field.network <<EOF
[Match]
Name=field

[Network]
Address=192.168.130.10/24
EOF

cat > /etc/systemd/network/21-bond-upstream.network <<EOF
[Match]
Name=upstream

[Network]
Address=192.168.140.10/24
EOF

echo "### Installing nftables config..."
cp "$WORKDIR/nftables.conf" /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

echo "### Rebooting in 5 seconds..."
sleep 5
reboot
