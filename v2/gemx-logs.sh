#!/usr/bin/env bash
# gemx-logs.sh — Navegador de logs com FZF (se disponível)
# Requer: jq; opcional: fzf, bat

set -u
LOGDIR="${GEMX_HOME:-$HOME/.config/gemx}/logs"

need(){ command -v "$1" >/dev/null 2>&1; }

if [ ! -d "$LOGDIR" ]; then
  echo "[ERR] Sem diretório de logs: $LOGDIR"
  exit 1
fi

files=( $(ls -1 "$LOGDIR"/audit-*.jsonl 2>/dev/null | sort) )
[ ${#files[@]} -gt 0 ] || { echo "[WARN] Sem arquivos audit-*.jsonl"; exit 0; }

merge() {
  cat "${files[@]}"
}

pretty() {
  if need bat; then bat -l json -pp
  else jq .; fi
}

if need fzf; then
  # Monta uma visão em colunas: ts | event | cmd | model | tail(argv)
  list_cmd='merge | jq -r "[.ts, .event, (.argv[0]//\"\"), (.model//\"\"), ((.argv[1:]//[])|join(\" \"))] | @tsv"'
  # shellcheck disable=SC2016
  preview='
    TS=$(echo {} | awk -F\"\t\" "{print \$1}");
    EVT=$(echo {} | awk -F\"\t\" "{print \$2}");
    CMD=$(echo {} | awk -F\"\t\" "{print \$3}");
    MODEL=$(echo {} | awk -F\"\t\" "{print \$4}");
    ARGS=$(echo {} | awk -F\"\t\" "{print \$5}");
    echo "ts: $TS"; echo "event: $EVT"; echo "cmd: $CMD"; echo "model: $MODEL"; echo "argv_tail: $ARGS"; echo; 
    merge | jq -c "select(.ts==\\\"$TS\\\" and .event==\\\"$EVT\\\" and (.argv[0]//\\\"\\\")==\\\"$CMD\\\")" | pretty
  '
  # Eval merge in sub-shell functions
  export -f merge pretty
  eval $list_cmd | fzf --with-nth=1,2,3,4 --delimiter="\t" --no-mouse --height=90% --reverse --border --preview="$preview" --preview-window=right:70%
else
  echo "[INFO] fzf não disponível; exibindo os logs combinados formatados:"
  merge | jq .
fi
