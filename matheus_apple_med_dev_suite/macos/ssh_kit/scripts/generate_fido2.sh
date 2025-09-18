#!/usr/bin/env bash
# Gera chave FIDO2 (security key). Requer OpenSSH com suporte a -sk e libfido2.
set -euo pipefail
if ! ssh -Q key | grep -q '^sk-.*ed25519'; then
  echo "[ERR] Seu OpenSSH não lista chaves sk- (FIDO2). Instale via Homebrew: brew install openssh libfido2"
  exit 2
fi
HN="$(scutil --get ComputerName 2>/dev/null || hostname)"
KEY="${1:-$HOME/.ssh/id_ed25519_sk}"
COMMENT="${2:-Matheus-FIDO2@$HN}"
[ -e "$KEY" ] && { echo "[ERR] arquivo existe: $KEY"; exit 1; }
echo "[INFO] Ao ser solicitado, TOQUE o token (YubiKey) ou valide com TouchID (se suportado)."
ssh-keygen -t ed25519-sk -O resident -O verify-required -a 100 -f "$KEY" -C "$COMMENT"
echo "[OK] chave FIDO2 criada: $KEY (privado) e $KEY.pub (público)"
echo "[INFO] publique com: ./scripts/ssh_copy_id.sh user@host \"$KEY.pub\""
pbcopy < "$KEY.pub" && echo "[OK] Public key copiada para o clipboard."
