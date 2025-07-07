#!/bin/bash
set -e

USER="stra"

echo "### Creating user $USER..."

if id "$USER" >/dev/null 2>&1; then
  echo "User $USER already exists."
else
  useradd -m -s /bin/bash "$USER"
  echo "User $USER created. You must set the password manually:"
  echo "  passwd $USER"
fi

echo "### Adding $USER to sudo group..."
usermod -aG sudo "$USER"

echo "### Adding $USER to docker group..."
usermod -aG docker "$USER"
