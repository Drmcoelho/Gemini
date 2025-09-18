#!/usr/bin/env bash
# Plugin: valida saída JSON contra chaves obrigatórias (checagem simples via jq)
# Uso:
#   ./plugins.d/json_validate.sh <json_file> key1 key2 key3...
set -euo pipefail
FILE="${1:-}"; shift || true
[ -f "$FILE" ] || { echo "[JSON-VAL] arquivo não existe: $FILE" >&2; exit 1; }
ok=1
for k in "$@"; do
  if ! jq -e "has(\"$k\")" "$FILE" >/dev/null; then
    echo "[JSON-VAL] falta chave obrigatória: $k" >&2
    ok=0
  fi
done
[ $ok -eq 1 ] && echo "[JSON-VAL] OK" || exit 3
