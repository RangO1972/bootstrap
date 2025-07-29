#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

USER="stra"

log info "Creating user $USER..."

if id "$USER" >/dev/null 2>&1; then
  echo "User $USER already exists."
else
  useradd -m -s /bin/bash "$USER"
  echo "User $USER created. You must set the password manually:"
  echo "  passwd $USER"
fi

log info "Adding $USER to sudo group..."
usermod -aG sudo "$USER"

