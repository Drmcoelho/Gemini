#!/usr/bin/env bash
# Instala sua chave pública no servidor remoto (sem ssh-copy-id)
set -euo pipefail
TARGET="${1:-}"
PUBKEY="${2:-$HOME/.ssh/id_ed25519.pub}"
[ -n "$TARGET" ] || { echo "Uso: $0 user@host [~/.ssh/key.pub]"; exit 1; }
[ -f "$PUBKEY" ] || { echo "[ERR] não encontrei: $PUBKEY"; exit 1; }

cat "$PUBKEY" | ssh -o PubkeyAuthentication=no -o PreferredAuthentications=keyboard-interactive,password "$TARGET" \
  'umask 077; mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && echo "[OK] chave instalada em ~/.ssh/authorized_keys"'
