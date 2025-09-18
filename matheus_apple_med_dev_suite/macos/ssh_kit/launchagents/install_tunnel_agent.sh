#!/usr/bin/env bash
# instala binários locais e um LaunchAgent de túnel (exemplo)
set -euo pipefail
PREFIX="$HOME/.local/bin"
mkdir -p "$PREFIX" "$HOME/Library/LaunchAgents"
install -m 0755 bin/sshx "$PREFIX/sshx"
install -m 0755 bin/ssh-tunnel "$PREFIX/ssh-tunnel"

# plists com envs (substitui vars)
NAME="${1:-sample}"
HOST="${HOST:-clinic-vm}"
LPORT="${LPORT:-5432}"
RHOST="${RHOST:-127.0.0.1}"
RPORT="${RPORT:-5432}"
IDENT="${IDENT:-$HOME/.ssh/id_ed25519}"

SRC="launchagents/com.mgx.ssh.tunnel.sample.plist"
DST="$HOME/Library/LaunchAgents/com.mgx.ssh.tunnel.${NAME}.plist"
sed -e "s|\${HOME}|$HOME|g" \
    -e "s|\${HOST}|$HOST|g" \
    -e "s|\${LPORT}|$LPORT|g" \
    -e "s|\${RHOST}|$RHOST|g" \
    -e "s|\${RPORT}|$RPORT|g" \
    -e "s|\${IDENT}|$IDENT|g" "$SRC" > "$DST"

launchctl unload "$DST" 2>/dev/null || true
launchctl load "$DST"
launchctl start "com.mgx.ssh.tunnel.${NAME}" || true
echo "[OK] LaunchAgent instalado: com.mgx.ssh.tunnel.${NAME}"
