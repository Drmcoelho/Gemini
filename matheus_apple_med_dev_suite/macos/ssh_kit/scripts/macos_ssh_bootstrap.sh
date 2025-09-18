#!/usr/bin/env bash
# macOS SSH Bootstrap — cria estrutura, checa versões e recomendações.
set -euo pipefail

# 1) diretórios e permissões
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# 2) inclui config.d no config principal (idempotente)
if ! grep -q "^Include ~/.ssh/config.d/*.conf" "$HOME/.ssh/config" 2>/dev/null; then
  {
    echo ""
    echo "# Managed by macos_ssh_kit"
    echo "Include ~/.ssh/config.d/*.conf"
  } >> "$HOME/.ssh/config"
fi

# 3) checa OpenSSH e suporte a FIDO2 (sk-keys)
echo "[INFO] ssh -V: $(ssh -V 2>&1)"
if ssh -Q key 2>/dev/null | grep -q '^sk-.*ed25519'; then
  echo "[OK] Suporte a 'security key' (FIDO2) detectado."
else
  cat <<'MSG'
[WARN] Seu OpenSSH não expõe chaves 'sk' (FIDO2).
- Recomendo instalar via Homebrew:
    brew install openssh libfido2
- Em Apple Silicon, garanta o PATH do Homebrew:
    export PATH="/opt/homebrew/bin:$PATH"
- Verifique novamente:
    ssh -Q key | grep sk-
MSG
fi

# 4) status do ssh-agent e Keychain
if ssh-add -l >/dev/null 2>&1; then
  echo "[OK] ssh-agent acessível."
else
  echo "[WARN] ssh-agent não respondeu. Em macOS o launchd gerencia o agente."
fi

echo "[DONE] Estrutura pronta. Próximos passos:"
echo "  1) ./scripts/generate_ed25519.sh           # chave clássica"
echo "  2) ./scripts/generate_fido2.sh             # chave FIDO2 (YubiKey/TouchID se suportado)"
echo "  3) ./scripts/enable_sshd_macos.sh          # ativar servidor (opcional)"
echo "  4) ./scripts/harden_sshd_macos.sh          # reforço de sshd (opcional)"
echo "  5) ./scripts/ssh_copy_id.sh user@host      # instalar sua chave no destino"
