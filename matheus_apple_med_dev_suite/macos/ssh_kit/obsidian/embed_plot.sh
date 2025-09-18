#!/usr/bin/env bash
# Embed a plot into an existing Obsidian note under "## Plots"
set -euo pipefail
NOTE="${1:-}"; PNG="${2:-}"
[ -f "$NOTE" ] && [ -f "$PNG" ] || { echo "Uso: $0 <note.md> <plot.png>"; exit 1; }
if ! grep -q '^## Plots' "$NOTE"; then
  printf "\n## Plots\n\n" >> "$NOTE"
fi
BASENAME="$(basename "$PNG")"
DIR="$(dirname "$NOTE")"
cp -f "$PNG" "$DIR/$BASENAME"
printf "![plot](%s)\n" "$BASENAME" >> "$NOTE"
echo "[OK] embed de $PNG em $NOTE"
