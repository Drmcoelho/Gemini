#!/usr/bin/env bash
# queue.sh — adiciona item na fila ./.queue
set -euo pipefail
mkdir -p .queue
file=".queue/$(date +%s%N).job"
printf "%s\n" "$*" > "$file"
echo "[QUEUE] added: $file"
