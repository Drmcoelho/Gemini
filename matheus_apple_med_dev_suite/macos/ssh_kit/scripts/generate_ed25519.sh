#!/usr/bin/env bash
# Gera chave Ed25519 com argon2 KDF e adiciona ao Keychain
set -euo pipefail
HN="$(scutil --get ComputerName 2>/dev/null || hostname)"
KEY="${1:-$HOME/.ssh/id_ed25519}"
COMMENT="${2:-Matheus@$HN}"
[ -e "$KEY" ] && { echo "[ERR] arquivo existe: $KEY"; exit 1; }
ssh-keygen -t ed25519 -a 100 -o -f "$KEY" -C "$COMMENT"
# adiciona ao agente e armazena passphrase no Keychain (novo OpenSSH)
if ssh-add --help 2>&1 | grep -q -- "--apple-use-keychain"; then
  ssh-add --apple-use-keychain "$KEY"
else
  # compatibilidade antiga: -K
  ssh-add -K "$KEY" || ssh-add "$KEY"
fi
echo "[OK] chave criada: $KEY"
echo "[INFO] publique com: ./scripts/ssh_copy_id.sh user@host \"$KEY.pub\""
pbcopy < "$KEY.pub" && echo "[OK] Public key copiada para o clipboard (pbcopy)."
