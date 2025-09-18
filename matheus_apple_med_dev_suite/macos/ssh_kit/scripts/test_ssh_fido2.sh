#!/usr/bin/env bash
# Testa conexão com chave FIDO2 exigindo toque/biometria (-O verify-required)
set -euo pipefail
TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "Uso: $0 user@host"; exit 1; }
echo "[INFO] Se solicitado, toque a chave de segurança ou use a biometria."
ssh -v "$TARGET" true
echo "[OK] Autenticação OK (exit 0)."
