#!/usr/bin/env bash
# Plugin: RAG simples com ripgrep (rg) para contexto local
# Uso:
#   ./plugins.d/rag.sh <kb_dir> <query> [max_bytes]
# Saída: contexto concatenado limitado por bytes (default 20000)
set -euo pipefail
KB="${1:-./kb}"
Q="${2:-}"
MAX="${3:-20000}"
[ -n "$Q" ] || { echo "[RAG] query vazia" >&2; exit 1; }
if ! command -v rg >/dev/null 2>&1; then echo "[RAG] ripgrep (rg) não instalado"; exit 2; fi
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
rg -n --no-heading --line-number --color=never -S --glob '!*{.git,.cache,node_modules}/*' "$Q" "$KB" > "$tmp" || true
# Compacta: caminho:linhas
ctx="$(cat "$tmp" | awk -F: '{print FILENAME":"$1" "$0}' 2>/dev/null || cat "$tmp")"
# Trunca por bytes
python3 - "$MAX" <<'PY'
import sys
limit=int(sys.argv[1]); data=sys.stdin.read().encode('utf-8')
sys.stdout.buffer.write(data[:limit])
PY
