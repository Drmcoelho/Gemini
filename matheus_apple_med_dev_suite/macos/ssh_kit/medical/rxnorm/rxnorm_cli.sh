#!/usr/bin/env bash
# rxnorm_cli.sh — consulta RxNorm (RxNav). Exemplos:
# ./rxnorm_cli.sh rxcui "metformin"           # nome->candidatos (approx)
# ./rxnorm_cli.sh properties 860975           # propriedades para RxCUI
set -euo pipefail
FN="${1:-rxcui}"; ARG="${2:-metformin}"
case "$FN" in
  rxcui)
    curl -sS "https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term=$(python3 - <<<'import urllib.parse;print(urllib.parse.quote(\"'\"$ARG\"'\"))')" | jq .
    ;;
  properties)
    curl -sS "https://rxnav.nlm.nih.gov/REST/rxcui/$ARG/properties.json" | jq .
    ;;
  interactions)
    curl -sS "https://rxnav.nlm.nih.gov/REST/interaction/interaction.json?rxcui=$ARG" | jq .
    ;;
  *)
    echo "Uso: $0 {rxcui <term>|properties <rxcui>|interactions <rxcui>}"; exit 1;;
esac
