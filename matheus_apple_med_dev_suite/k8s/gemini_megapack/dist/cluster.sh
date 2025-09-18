#!/usr/bin/env bash
# dist/cluster.sh — executa um comando em todos os hosts listados em dist/hosts
# Requer: ssh configurado (chave sem senha recomendável). Opcional: parallel/pssh.
set -euo pipefail
HOSTS_FILE="${GEMX_HOSTS:-dist/hosts}"
CMD="${*:-uname -a}"

have(){ command -v "$1" >/dev/null 2>&1; }

mapfile -t HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | sed '/^\s*$/d')
[ "${#HOSTS[@]}" -gt 0 ] || { echo "[DIST] Nenhum host em $HOSTS_FILE"; exit 1; }

if have parallel; then
  printf "%s\n" "${HOSTS[@]}" | parallel -j0 --line-buffer 'h={}; u="${h%%@*}"; p="${h##*:}"; h="${h%:*}"; ssh -p "${p:-22}" "$h" "{}" ::: "'"$CMD"'"'
elif have pssh; then
  pssh -h "$HOSTS_FILE" -i "$CMD"
else
  echo "[DIST] Rodando em loop (instale parallel ou pssh p/ velocidade)..."
  for H in "${HOSTS[@]}"; do
    P="${H##*:}"; S="${H%:*}"
    echo "[DIST] -> $S (porta ${P:-22})"
    ssh -p "${P:-22}" "$S" "$CMD" || echo "[DIST] falhou em $S"
  done
fi
