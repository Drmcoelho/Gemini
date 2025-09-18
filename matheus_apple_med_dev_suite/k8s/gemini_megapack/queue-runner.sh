#!/usr/bin/env bash
# queue-runner.sh — processa itens ./.queue FIFO
set -euo pipefail
dir=".queue"
[ -d "$dir" ] || { echo "[QUEUE] sem diretório .queue"; exit 0; }
for f in $(ls -1 "$dir"/*.job 2>/dev/null | sort); do
  ./verify-job.sh "$f" || { echo "[QUEUE] assinatura inválida, pulando $f"; rm -f "$f"; continue; }
  echo "[QUEUE] run: $f -> $(cat "$f")"
  bash -lc "$(cat "$f")" || echo "[QUEUE] erro em $f"
  rm -f "$f"
done
echo "[QUEUE] done."
