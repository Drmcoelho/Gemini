#!/usr/bin/env bash
# instala utilitários médicos e LaunchAgent de sync
set -euo pipefail
PREFIX="$HOME/.local/med"
mkdir -p "$PREFIX" "$HOME/Library/LaunchAgents"
install -m 0755 medical/cron/refresh_ctgov.sh "$PREFIX/refresh_ctgov.sh"
cp -f medical/cron/com.mgx.med.ctgov.refresh.plist "$HOME/Library/LaunchAgents/"
launchctl unload "$HOME/Library/LaunchAgents/com.mgx.med.ctgov.refresh.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.mgx.med.ctgov.refresh.plist"
echo "[OK] Agendado: com.mgx.med.ctgov.refresh"
