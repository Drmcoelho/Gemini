#!/usr/bin/env bash
# fhir_cli.sh — cliente FHIR simples (HAPI ou outro). Usa curl + jq.
# Uso:
#   ./fhir_cli.sh base "Patient/123"
#   ./fhir_cli.sh base "Observation?code=loinc|718-7&subject=Patient/123"
set -euo pipefail
BASE="${1:-https://hapi.fhir.org/baseR4}"
PATHQ="${2:-Patient?_count=5}"
curl -sS -H 'Accept: application/fhir+json' "$BASE/$PATHQ" | jq .
