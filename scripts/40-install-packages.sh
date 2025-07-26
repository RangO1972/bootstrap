#!/bin/bash
set -e

echo "[40] ### Updating package lists..."
apt-get update

echo "[40] Installo kernel e header da backports..."
apt-get install -y -t bookworm-backports linux-image-amd64 linux-headers-amd64

echo "[40] ### Installing packages..."
apt-get install -y $(cat /opt/stradcs-bootstrap/configs/packages.txt)
