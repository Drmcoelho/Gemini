#!/usr/bin/env bash
# ZeroTier: join a network and authorize in the controller UI.
set -euo pipefail
NET="${1:-}"
[ -n "$NET" ] || { echo "Uso: $0 <NETWORK_ID>"; exit 1; }
if ! command -v zerotier-cli >/dev/null 2>&1; then
  echo "[ERR] zerotier-cli não encontrado. Instale: brew install zerotier-one"
  exit 1
fi
sudo -v
sudo /usr/local/sbin/zerotier-one -d || true
sleep 1
sudo zerotier-cli join "$NET"
echo "[INFO] Authorize this node in the ZeroTier web UI (controller)."
sudo zerotier-cli listnetworks
