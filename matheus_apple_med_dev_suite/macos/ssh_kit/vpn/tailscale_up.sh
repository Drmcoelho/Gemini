#!/usr/bin/env bash
# Tailscale quick bootstrap (login + up). Requires: tailscale
set -euo pipefail
if ! command -v tailscale >/dev/null 2>&1; then
  echo "[ERR] tailscale não encontrado. Instale via brew: brew install --cask tailscale"
  exit 1
fi

# Optional args (e.g., --ssh to allow inbound SSH, or --advertise-tags)
ARGS=("$@")
sudo -v
sudo tailscale up "${ARGS[@]}"
tailscale status
echo "[OK] Tailscale ativo. MagicDNS e TS SSH (se habilitado)."
