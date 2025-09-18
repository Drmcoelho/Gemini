#!/usr/bin/env bash
set -euo pipefail
DST="$HOME/Library/LaunchAgents/com.mgx.med.obsidian.sync.plist"
cp -f obsidian/com.mgx.med.obsidian.sync.plist "$DST"
launchctl unload "$DST" 2>/dev/null || true
launchctl load "$DST"
echo "[OK] LaunchAgent instalado: com.mgx.med.obsidian.sync"
echo "Defina as variáveis FHIR_BASE, PATIENT_ID e OB_VAULT dentro do plist (ou via env) antes de carregar."
