#!/usr/bin/env bash
# Aplica reforços no sshd (somente chaves; sem senha; sem root login; PAM; etc.)
set -euo pipefail
CONF_DIR="/etc/ssh/sshd_config.d"
CONF_FILE="$CONF_DIR/99-hardening.conf"
sudo mkdir -p "$CONF_DIR"
sudo tee "$CONF_FILE" >/dev/null <<'CONF'
# 99-hardening.conf — gerado por macos_ssh_kit
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
PermitRootLogin no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
# limite a grupos se desejar:
# AllowGroups com.apple.access_ssh admin
CONF

echo "[OK] Hardening escrito em: $CONF_FILE"
echo "[INFO] Validando sintaxe..."
sudo /usr/sbin/sshd -t && echo "[OK] sshd_config OK" || { echo "[ERR] validação falhou"; exit 2; }

echo "[INFO] Reiniciando sshd..."
sudo launchctl kickstart -k system/com.openssh.sshd || true
echo "[DONE] sshd reforçado."
