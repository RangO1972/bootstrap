#!/bin/bash
set -e

echo "[10-setup-essential] Abilitazione e attivazione systemd-networkd e resolved..."
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl start systemd-networkd.service
systemctl start systemd-resolved.service

echo "[10-setup-essential] Verifica completata."
