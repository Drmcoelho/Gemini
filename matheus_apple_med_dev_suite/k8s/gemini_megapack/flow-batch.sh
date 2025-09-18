#!/usr/bin/env bash
# flow-batch.sh — executa múltiplos flows com retries e backoff exponencial com jitter
# Requer: bash, jq; Opcional: GNU parallel
#
# Uso básico:
#   ./flow-batch.sh [--retries 3] [--base 2] [--max 60] [--jitter 5] [--concurrency 1] [--manifest flows.txt|.yml] [paths...]
#
# Fontes de flows:
#   - paths...           (lista de arquivos *.yml/*.yaml)
#   - --manifest FILE    (txt: 1 caminho por linha; yaml: chave 'flows' com lista)
#   - sem args           => varre diretório ./flows/*.yml*
#
set -euo pipefail

RETRIES=3
BASE=2          # segundos
MAX=60          # segundos
JITTER=5        # segundos extra [0..JITTER]
CONCURRENCY=1
MANIFEST=""
ALLOW_HOURS=""   # ex: "08:00-12:00,14:00-18:00"
ALLOW_DAYS=""    # ex: "Mon,Tue,Wed,Thu,Fri"

LOGDIR="${GEMX_HOME:-$HOME/.config/gemx}/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/flowbatch-$(date -u +%Y%m%d).jsonl"

have(){ command -v "$1" >/dev/null 2>&1; }
now_iso(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }

usage(){
  cat <<HLP
Uso:
  ./flow-batch.sh [--retries N] [--base SEC] [--max SEC] [--jitter SEC] [--concurrency N] [--manifest FILE] \
                  [--allow-hours "HH:MM-HH:MM[,HH:MM-HH:MM]"] [--allow-days "Mon,Tue,..."] [flows...]
Exemplos:
  ./flow-batch.sh --concurrency 4 flows/*.yml
  ./flow-batch.sh --manifest flows.txt --retries 2 --base 3 --max 45 --jitter 7
HLP
}

# args
while [ $# -gt 0 ]; do
  case "$1" in
    --retries) RETRIES="$2"; shift 2;;
    --base) BASE="$2"; shift 2;;
    --max) MAX="$2"; shift 2;;
    --jitter) JITTER="$2"; shift 2;;
    --concurrency) CONCURRENCY="$2"; shift 2;;
    --manifest) MANIFEST="$2"; shift 2;;
    --allow-hours) ALLOW_HOURS="$2"; shift 2;;
    --allow-days) ALLOW_DAYS="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) break;;
  esac
done

collect_flows(){
  local arr=()
  if [ $# -gt 0 ]; then
    arr=("$@")
  elif [ -n "$MANIFEST" ]; then
    if [[ "$MANIFEST" =~ \.ya?ml$ ]]; then
      if have yq; then
        mapfile -t arr < <(yq -r '.flows[]' "$MANIFEST")
      else
        echo "[WARN] Sem yq; esperando manifesto TXT (um caminho por linha)."; arr=()
      fi
    else
      mapfile -t arr < <(grep -v '^\s*#' "$MANIFEST" | sed '/^\s*$/d')
    fi
  else
    mapfile -t arr < <(ls -1 flows/*.{yml,yaml} 2>/dev/null || true)
  fi
  printf "%s\n" "${arr[@]}"
}

log_jsonl(){
  # $1 event, $2 flow, $3 status, $4 attempt, $5 duration, $6 msg
  printf '{"ts":"%s","event":"%s","flow":"%s","status":%d,"attempt":%d,"duration":%d,"msg":%s}\n' \
    "$(now_iso)" "$1" "$2" "$3" "$4" "$5" "$(printf '%s' "$6" | jq -Rsa .)" >> "$LOGFILE"
}

run_one(){
  local flow="$1"
  local attempt=1
  local st=0
  local start end dur
  while [ $attempt -le $RETRIES ]; do
    wait_until_window
    start=$(date +%s)
    ./gemx.sh flow "$flow" >/dev/null 2>&1
    st=$?
    end=$(date +%s); dur=$(( end - start ))
    if [ $st -eq 0 ]; then
      log_jsonl "finish" "$flow" $st $attempt $dur "ok"
      return 0
    else
      log_jsonl "error" "$flow" $st $attempt $dur "retrying"
      # backoff
      sleep_for=$(( BASE * (2 ** (attempt - 1)) ))
      [ $sleep_for -gt $MAX ] && sleep_for=$MAX
      if [ "$JITTER" -gt 0 ]; then
        j=$(( RANDOM % (JITTER + 1) ))
        sleep_for=$(( sleep_for + j ))
      fi
      sleep "$sleep_for"
    fi
    attempt=$(( attempt + 1 ))
  done
  # última tentativa falhou
  log_jsonl "fail" "$flow" $st $((attempt-1)) 0 "exceeded retries"
  return 1
}

# Export for parallel
in_window(){
  # returns 0 if current local time is within allowed windows; 0 if no constraints
  [ -z "$ALLOW_HOURS$ALLOW_DAYS" ] && return 0
  # day check
  if [ -n "$ALLOW_DAYS" ]; then
    local day=$(date +%a)  # Mon Tue Wed Thu Fri Sat Sun
    case "$ALLOW_DAYS" in
      *"$day"*) : ;; 
      *) return 1 ;;
    esac
  fi
  # hours check
  if [ -n "$ALLOW_HOURS" ]; then
    local now=$(date +%H:%M)
    IFS=',' read -r -a ranges <<< "$ALLOW_HOURS"
    for r in "${ranges[@]}"; do
      local s="${r%-*}"; local e="${r#*-}"
      # handle wrap-around? simple: assume s<=e same day
      if [[ "$now" > "$s" && "$now" < "$e" ]] || [ "$now" = "$s" ] || [ "$now" = "$e" ]; then
        return 0
      fi
    endfor=0
    return 1
  fi
  return 0
}

wait_until_window(){
  # block until inside window (if configured)
  until in_window; do
    echo "[FLOW-BATCH] Fora da janela (dias/horas). Aguardando 60s..."
    sleep 60
  done
}

export -f run_one log_jsonl now_iso in_window wait_until_window
export RETRIES BASE MAX JITTER LOGFILE ALLOW_HOURS ALLOW_DAYS

mapfile -t FLOWS < <(collect_flows "$@")
[ ${#FLOWS[@]} -gt 0 ] || { echo "[FLOW-BATCH] Nenhum flow encontrado."; exit 1; }

echo "[FLOW-BATCH] Execuções: ${#FLOWS[@]} | conc=$CONCURRENCY retries=$RETRIES base=$BASE max=$MAX jitter=$JITTER"
ok=0; fail=0

if have parallel && [ "$CONCURRENCY" -gt 1 ]; then
  parallel -j "$CONCURRENCY" --halt now,fail=1 run_one ::: "${FLOWS[@]}" && ok=1 || ok=0
  # Não conseguimos contar individualmente aqui sem um arquivo temp; o JSONL registra.
else
  for f in "${FLOWS[@]}"; do
    if run_one "$f"; then ok=$((ok+1)); else fail=$((fail+1)); fi
  done
fi

echo "[FLOW-BATCH] Concluído. Ver resumo no JSONL: $LOGFILE"
exit 0
