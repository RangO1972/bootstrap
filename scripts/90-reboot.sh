#!/bin/bash
set -e

: "${WORKDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WORKDIR/lib/common.sh"

log info "Rebooting in 5 seconds..."
sleep 1
log info "Rebooting in 4 seconds..."
sleep 1
log info "Rebooting in 3 seconds..."
sleep 1
log info "Rebooting in 2 seconds..."
sleep 1
log info "Rebooting in 1 seconds..."
sleep 1
log info "Rebooting..."
reboot
