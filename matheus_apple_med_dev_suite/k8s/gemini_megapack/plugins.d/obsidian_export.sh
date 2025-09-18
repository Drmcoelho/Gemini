#!/usr/bin/env bash
# Plugin: exporta resposta para Obsidian (vault do others.json)
# Uso:
#   ./plugins.d/obsidian_export.sh "<title>" "<content>"
set -euo pipefail
TITLE="${1:-Gemx Note}"
CONTENT="${2:-}"
VAULT="${OBSIDIAN_VAULT:-}"
if [ -z "$VAULT" ]; then
  echo "[OBS] Set OBSIDIAN_VAULT ou configure em others.json.integrations.obsidian_vault" >&2
  exit 2
fi
ts="$(date -Iseconds | tr ':' '-')"
file="$VAULT/${ts} ${TITLE}.md"
mkdir -p "$(dirname "$file")"
printf "# %s\n\n%s\n" "$TITLE" "$CONTENT" > "$file"
echo "[OBS] Salvo em: $file"
