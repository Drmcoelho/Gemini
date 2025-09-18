#!/usr/bin/env bash
set -euo pipefail
command -v tailscale >/dev/null 2>&1 || { echo "tailscale não instalado"; exit 1; }
tailscale status
echo
tailscale ip -4 || true
tailscale ip -6 || true
