#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

echo "$TAG -Updating package lists..."
apt-get update

echo "$TAG -Installo kernel e header da backports..."
apt-get install -y -t bookworm-backports linux-image-amd64 linux-headers-amd64

echo "$TAG -### Installing packages..."
apt-get install -y $(cat /opt/stradcs-bootstrap/configs/packages.txt)
