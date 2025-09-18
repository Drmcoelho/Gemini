#!/usr/bin/env bash
# Aplica ACL via Tailscale Admin API (requer TS_API_KEY e TS_TAILNET)
set -euo pipefail
[ -n "${TS_API_KEY:-}" ] || { echo "[ERR] TS_API_KEY vazio"; exit 1; }
[ -n "${TS_TAILNET:-}" ] || { echo "[ERR] TS_TAILNET vazio (ex: example.gmail.com)"; exit 1; }
FILE="${1:-vpn/tailscale_acl.example.json}"
curl -sS -X POST \
  -H "Authorization: Bearer $TS_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary "@$FILE" \
  "https://api.tailscale.com/api/v2/tailnet/$TS_TAILNET/acl"
echo
echo "[OK] ACL enviada. Revise no Admin UI."
