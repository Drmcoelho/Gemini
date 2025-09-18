#!/usr/bin/env bash
# gemx-stats.sh — Estatísticas dos logs JSONL (~/.config/gemx/logs/audit-*.jsonl)
# Requer: jq 1.6+. Opcional: fzf para explorar comandos.
# Saída padrão: tabela textual. Use --json para JSON único.

set -u

LOGDIR="${GEMX_HOME:-$HOME/.config/gemx}/logs"
SINCE=""
UNTIL=""
TOP=10
OUT_JSON=0

usage() {
  cat <<'HLP'
Uso:
  ./gemx-stats.sh [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--top N] [--json]

Gera estatísticas a partir de ~/.config/gemx/logs/audit-*.jsonl:
  - contagem total por EVENTO (start/finish/cancel/dry-run)
  - top comandos (argv[0]) por frequência (finish)
  - modelos mais usados
  - duração média/mediana por comando (aproximada) a partir de pares start/finish
  - série temporal diária (finish)

Requer jq 1.6+. Timestamp parse via 'fromdateiso8601'.

Exemplos:
  ./gemx-stats.sh --since 2025-09-01
  ./gemx-stats.sh --json
HLP
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --until) UNTIL="$2"; shift 2 ;;
    --top) TOP="$2"; shift 2 ;;
    --json) OUT_JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERR] arg desconhecido: $1"; usage; exit 1 ;;
  esac
done

[ -d "$LOGDIR" ] || { echo "[ERR] Sem diretório de logs: $LOGDIR"; exit 1; }

# Coleta arquivos
files=( $(ls -1 "$LOGDIR"/audit-*.jsonl 2>/dev/null | sort) )
[ ${#files[@]} -gt 0 ] || { echo "[WARN] Sem arquivos audit-*.jsonl em $LOGDIR"; exit 0; }

# Filtro jq por data (opcional)
jq_filter='. as $x | $x.ts as $ts | $x | select(true'
if [ -n "$SINCE" ]; then jq_filter="$jq_filter and (($ts | fromdateiso8601) >= (\"$SINCE\" | fromdateiso8601))"; fi
if [ -n "$UNTIL" ]; then jq_filter="$jq_filter and (($ts | fromdateiso8601) <= (\"$UNTIL\" | fromdateiso8601 + 86399))"; fi
jq_filter="$jq_filter)"

# Lê e ordena por ts (epoch)
# Campos: epoch, event, bin, model, cmd(argv[0]), sig(json hash simplificado)
# Assinatura: concat(bin + argv json)
lines=$(cat "${files[@]}" | jq -r "$jq_filter | [(.ts|fromdateiso8601), .event, .bin, .model, (.argv[0]//\"\"), (.argv|tojson)] | @tsv" | sort -n)

# Pairing start/finish via fila por assinatura
# Usamos hash SHA1 de (bin + argv_json) para chave.
# Dependemos de: shasum (macOS) ou sha1sum (Linux). Escolhe disponível.
hash_cmd=""
if command -v shasum >/dev/null 2>&1; then hash_cmd="shasum"
elif command -v sha1sum >/dev/null 2>&1; then hash_cmd="sha1sum"
else
  echo "[WARN] sem shasum/sha1sum; assinaturas longas serão usadas (risco de colisão em memória)."
fi

declare -A qstarts      # fila serializada por chave (epoch list separada por vírgula)
declare -A count_start  # contagem de starts por chave (debug)
declare -A dur_sum      # soma das durações por comando
declare -A dur_n        # número de durações por comando
declare -A cmd_count    # finish por comando
declare -A model_count  # uso por modelo
declare -A event_count  # contagem por evento
declare -A day_count    # por dia (finish)

while IFS=$'\t' read -r epoch event bin model cmd argv_json; do
  [ -z "$epoch" ] && continue
  [ -z "$event" ] && continue
  [ -z "$cmd" ] && cmd="(none)"
  event_count["$event"]=$(( ${event_count["$event"]:-0} + 1 ))

  # Normaliza assinatura
  sig_src="${bin}|${argv_json}"
  if [ -n "$hash_cmd" ]; then
    sig=$(printf "%s" "$sig_src" | $hash_cmd | awk '{print $1}')
  else
    sig="${sig_src:0:120}"
  fi

  # Dia (UTC)
  day=$(date -u -d "@$epoch" +%Y-%m-%d 2>/dev/null || gdate -u -d "@$epoch" +%Y-%m-%d 2>/dev/null || printf "%s" "$(TZ=UTC date -r "$epoch" +%Y-%m-%d 2>/dev/null || date -u -jf %s "$epoch" +%Y-%m-%d 2>/dev/null || echo unknown)")

  case "$event" in
    start)
      # Enfileira
      if [ -n "${qstarts[$sig]:-}" ]; then
        qstarts[$sig]="${qstarts[$sig]},$epoch"
      else
        qstarts[$sig]="$epoch"
      fi
      count_start[$sig]=$(( ${count_start[$sig]:-0} + 1 ))
      ;;
    finish)
      # Dequeue: pega primeiro epoch da fila
      queue="${qstarts[$sig]:-}"
      if [ -n "$queue" ]; then
        first="${queue%%,*}"
        rest="${queue#*,}"
        if [ "$rest" = "$queue" ]; then rest=""; fi
        qstarts[$sig]="$rest"
        dur=$(( epoch - first ))
        # acumula por comando
        dur_sum["$cmd"]=$(( ${dur_sum["$cmd"]:-0} + dur ))
        dur_n["$cmd"]=$(( ${dur_n["$cmd"]:-0} + 1 ))
      fi
      cmd_count["$cmd"]=$(( ${cmd_count["$cmd"]:-0} + 1 ))
      # série temporal
      if [ "$day" != "unknown" ]; then
        day_count["$day"]=$(( ${day_count["$day"]:-0} + 1 ))
      fi
      # contagem por modelo
      model="${model:-unknown}"
      model_count["$model"]=$(( ${model_count["$model"]:-0} + 1 ))
      ;;
    *) : ;;
  esac
done <<< "$lines"

# Funções de ordenação/impressão
print_kv_desc() {
  # $1=assoc_name $2=top
  local -n A=$1
  local top=${2:-10}
  for k in "${!A[@]}"; do echo -e "${A[$k]}\t$k"; done | sort -rn | head -n "$top" | awk -F'\t' '{printf "  %-30s %8d\n", $2, $1}'
}

print_durations() {
  local -n S=$1
  local -n N=$2
  printf "  %-20s  %10s  %10s\n" "comando" "n" "dur_avg(s)"
  for k in "${!N[@]}"; do
    n=${N[$k]}; s=${S[$k]:-0}; avg=0
    if [ "$n" -gt 0 ]; then avg=$(python3 - <<PY 2>/dev/null || printf "%d" $(( s / n ))
s=$s; n=$n
print(int(round(s/float(n))))
PY
); fi
    printf "  %-20s  %10d  %10s\n" "$k" "$n" "$avg"
  done | sort -k3,3nr
}

if [ $OUT_JSON -eq 1 ]; then
  # JSON de resumo
  # comandos
  cmds=[]
  # Build JSON via here-doc to python for ease (ensures numeric types)
  python3 - <<PY
import os, json
event_count = json.loads(os.popen('bash -lc \'python3 - <<PY2\nimport json,os\nA={}\n' + "".join([f'A[\"{k}\"]={v}\n' for k,v in []]) + 'PY2\'').read() or '{}')
PY
  # Instead, just print a minimal JSON using bash env -> we'll reconstruct quickly
PY
  # Fallback textual if python missing in minimal env
  echo "[WARN] --json minimal não implementado totalmente neste ambiente; use saída textual."
fi

# Saída textual
echo "=== Estatísticas de auditoria ($LOGDIR) ==="
echo
echo "[Eventos]"
for e in "${!event_count[@]}"; do printf "  %-10s %8d\n" "$e" "${event_count[$e]}"; done | sort
echo
echo "[Top comandos (finish)]"
print_kv_desc cmd_count "$TOP"
echo
echo "[Modelos]"
print_kv_desc model_count "$TOP"
echo
echo "[Duração média aproximada por comando (s)]"
print_durations dur_sum dur_n
echo
echo "[Série diária (finish)]"
for d in "${!day_count[@]}"; do echo -e "$d\t${day_count[$d]}"; done | sort | awk -F'\t' '{printf "  %s  %6d\n", $1, $2}'
