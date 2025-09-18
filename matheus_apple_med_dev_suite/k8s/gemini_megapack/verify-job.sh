#!/usr/bin/env bash
# verify-job.sh — verifica SHA256 do job contra ledger
set -euo pipefail
JOB_FILE="${1:-}"
[ -f "$JOB_FILE" ] || { echo "[VERIFY] arquivo inexistente: $JOB_FILE" >&2; exit 1; }
SHA=$(shasum -a 256 "$JOB_FILE" 2>/dev/null | awk '{print $1}')
[ -n "$SHA" ] || SHA=$(sha256sum "$JOB_FILE" 2>/dev/null | awk '{print $1}')
grep -R "\"file\":\"$JOB_FILE\"" .attest/*.jsonl 2>/dev/null | grep -q "\"sha256\":\"$SHA\"" && {
  echo "[VERIFY] OK: $JOB_FILE sha256=$SHA"
  exit 0
}
echo "[VERIFY] FALHA: $JOB_FILE sha256=$SHA não encontrado na atestação."
exit 3
