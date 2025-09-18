#!/usr/bin/env bash
# dist/deploy.sh — empacota o projeto e envia/descompacta remotamente
# Requer: tar, scp, ssh. Opcional: parallel para fan-out.
set -euo pipefail
HOSTS_FILE="${GEMX_HOSTS:-dist/hosts}"
DEST_DIR="${1:-~/gemx}"
ARCHIVE="gemx_bundle.tar.gz"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# monta bundle excluindo dot-caches e o próprio archive
tar --exclude="*.tar.gz" --exclude="__pycache__" --exclude=".git" -czf "$tmp/$ARCHIVE" .

mapfile -t HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | sed '/^\s*$/d')
[ "${#HOSTS[@]}" -gt 0 ] || { echo "[DIST] Sem hosts"; exit 1; }

for H in "${HOSTS[@]}"; do
  P="${H##*:}"; S="${H%:*}"
  echo "[DIST] deploy -> $S:$DEST_DIR"
  ssh -p "${P:-22}" "$S" "mkdir -p $DEST_DIR"
  scp -P "${P:-22}" "$tmp/$ARCHIVE" "$S:$DEST_DIR/"
  ssh -p "${P:-22}" "$S" "cd $DEST_DIR && tar -xzf $ARCHIVE && rm -f $ARCHIVE"
done
echo "[DIST] deploy concluído."
