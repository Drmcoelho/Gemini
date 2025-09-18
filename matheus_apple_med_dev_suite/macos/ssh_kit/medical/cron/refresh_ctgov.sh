#!/usr/bin/env bash
# refresh_ctgov.sh — baixa estudos sobre tema e salva por data
set -euo pipefail
TOPIC="${TOPIC:-sepsis}"
OUTDIR="${OUTDIR:-$HOME/Library/Application Support/med-data/clinicaltrials}"
mkdir -p "$OUTDIR"
STAMP="$(date +%F)"
QS="query.term=$TOPIC&page.size=50&fields=NCTId,BriefTitle,StudyType,OverallStatus,Conditions"
curl -sS "https://clinicaltrials.gov/api/v2/studies?$QS" > "$OUTDIR/${STAMP}-${TOPIC}.json"
echo "[OK] salvo em $OUTDIR/${STAMP}-${TOPIC}.json"
