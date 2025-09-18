#!/usr/bin/env bash
# openfda_drug.sh — consulta OpenFDA (label/drug/event). Sem token, com paging simples.
# Ex: ./openfda_drug.sh label 'openfda.brand_name:"metformin"'
set -euo pipefail
EP="${1:-label}"; Q="${2:-openfda.brand_name:\"aspirin\"}"; LIMIT="${3:-5}"; SKIP="${4:-0}"
curl -sS "https://api.fda.gov/drug/${EP}.json?search=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "$Q")&limit=$LIMIT&skip=$SKIP" | jq .
