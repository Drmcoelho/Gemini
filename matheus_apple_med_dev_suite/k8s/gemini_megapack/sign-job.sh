#!/usr/bin/env bash
# sign-job.sh — assina um comando/arquivo de job com SHA256 e registra atestação
set -euo pipefail
JOB_FILE="${1:-}"
[ -f "$JOB_FILE" ] || { echo "[SIGN] arquivo inexistente: $JOB_FILE" >&2; exit 1; }
SHA=$(shasum -a 256 "$JOB_FILE" 2>/dev/null | awk '{print $1}')
[ -n "$SHA" ] || SHA=$(sha256sum "$JOB_FILE" 2>/dev/null | awk '{print $1}')
[ -n "$SHA" ] || { echo "[SIGN] não consegui calcular SHA256"; exit 2; }

TS=$(date -Iseconds -u)
WHO=$(whoami)@"$(hostname)"
CMD=$(cat "$JOB_FILE")

mkdir -p .attest
LEDGER=".attest/attest-$(date -u +%Y%m%d).jsonl"
printf '{"ts":"%s","who":"%s","job":"%s","sha256":"%s","file":"%s"}\n' "$TS" "$WHO" "$(echo "$CMD" | sed 's/"/\\"/g')" "$SHA" "$JOB_FILE" >> "$LEDGER"
echo "[SIGN] $JOB_FILE sha256=$SHA"
