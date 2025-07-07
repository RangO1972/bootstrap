#!/bin/bash
set -e

echo "### Updating package lists..."
apt-get update

echo "### Installing packages..."
apt-get install -y $(cat /opt/stradcs-bootstrap/configs/packages.txt)
