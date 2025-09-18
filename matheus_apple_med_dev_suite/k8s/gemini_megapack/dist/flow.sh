#!/usr/bin/env bash
# dist/flow.sh — dispara um flow em todos os hosts (após deploy)
# Uso: dist/flow.sh <dest_dir> <flow_file_relativo>
set -euo pipefail
HOSTS_FILE="${GEMX_HOSTS:-dist/hosts}"
DEST_DIR="${1:-~/gemx}"
FLOW_REL="${2:-flows/flow_example.yml}"
CMD="cd $DEST_DIR/gemini_megapack && ./gemx.sh flow $FLOW_REL"

bash dist/cluster.sh "$CMD"
