#!/usr/bin/env bash
# dist/flow-batch.sh — roda batch de flows em todos os hosts
# Uso: dist/flow-batch.sh <dest_dir> [args da flow-batch.sh...]
set -euo pipefail
DEST_DIR="${1:-~/gemx}"; shift || true
CMD="cd $DEST_DIR/gemini_megapack && ./flow-batch.sh $*"
bash dist/cluster.sh "$CMD"
