#!/usr/bin/env bash
# tests/self-test.sh — smoke tests não-destrutivos
set -e
echo "[TEST] jq version: $(jq --version)"
[ -f ./gemx.sh ] && echo "[TEST] gemx.sh OK"
[ -f ./others.json ] && jq -e '.' ./others.json >/dev/null && echo "[TEST] others.json OK"
echo "[TEST] DONE"
