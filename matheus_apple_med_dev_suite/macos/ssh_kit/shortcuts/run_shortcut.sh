#!/usr/bin/env bash
# run_shortcut.sh — dispara um Atalho por nome, com input opcional
set -euo pipefail
NAME="${1:-}"; shift || true
[ -n "$NAME" ] || { echo "Uso: $0 'Shortcut Name' [--input '...']"; exit 1; }
shortcuts run "$NAME" "$@"
