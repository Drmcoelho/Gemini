#!/usr/bin/env bash
# Ativa o servidor SSH no macOS e limita acesso ao grupo com.apple.access_ssh
set -euo pipefail
if ! command -v systemsetup >/dev/null 2>&1; then
  echo "[ERR] systemsetup não encontrado (macOS apenas)."; exit 1
fi
echo "[INFO] Habilitando Remote Login (sshd)..."
sudo systemsetup -setremotelogin on

# Garante grupo de acesso e adiciona o usuário atual
if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
  echo "[INFO] Concedendo acesso SSH ao usuário atual via com.apple.access_ssh"
  sudo dseditgroup -o edit -a "$USER" -t user com.apple.access_ssh
fi

# Reinicia o daemon
echo "[INFO] Reiniciando sshd..."
sudo launchctl kickstart -k system/com.openssh.sshd || true
echo "[OK] Remote Login ativo. Verifique com: sudo systemsetup -getremotelogin"
