#!/bin/bash
set -e
TAG="\033[1;37m[$(basename "$0" .sh)]\033[0m"

USER="stra"

echo "$TAG - Creating user $USER..."

if id "$USER" >/dev/null 2>&1; then
  echo "User $USER already exists."
else
  useradd -m -s /bin/bash "$USER"
  echo "User $USER created. You must set the password manually:"
  echo "  passwd $USER"
fi

echo "$TAG - Adding $USER to sudo group..."
usermod -aG sudo "$USER"

echo "$TAG - Adding $USER to docker group..."
usermod -aG docker "$USER"
