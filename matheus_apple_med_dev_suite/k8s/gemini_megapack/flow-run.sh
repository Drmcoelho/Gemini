#!/usr/bin/env bash
# flow-run.sh — executa pipeline YAML de flows/*.yml
set -euo pipefail
FLOW="${1:-flows/flow_example.yml}"
[ -f "$FLOW" ] || { echo "[FLOW] arquivo não encontrado: $FLOW" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
get(){ jq -r "$1" "$FLOW"; }
# yq preferido
if have yq; then
  steps=$(yq '.steps' "$FLOW")
else
  echo "[FLOW] yq não instalado; tentando jq (requere YAML válido JSON-like)."
  steps=$(python3 - <<PY 2>/dev/null || echo "[]"
import yaml, json, sys
print(json.dumps(yaml.safe_load(open(sys.argv[1]).read()).get('steps', [])))
PY
"$FLOW")
fi

# Variáveis de contexto
declare -A CTX
last_out=""

len=$(python3 - <<PY
import json,sys; print(len(json.load(sys.stdin)))
PY <<<"$steps")

for i in $(seq 0 $((len-1))); do
  name=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('name','step'))
PY
)
  run=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('run',''))
PY
)
  echo "[FLOW] >>> $name ($run)"
  case "$run" in
    rag)
      kb=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('args',{}).get('kb','./kb'))
PY
)
      q=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('args',{}).get('query',''))
PY
)
      mb=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('args',{}).get('max_bytes','16000'))
PY
)
      out="$(./plugins.d/rag.sh "$kb" "$q" "$mb" 2>/dev/null || true)"
      CTX["ctx"]="$out"
      ;;
    gen)
      prompt=$(python3 - <<'PY' <<<"$steps"
import json,sys,os
i=int(os.environ.get('IDX',0))
d=json.load(sys.stdin)[i]
print(d.get('prompt',''))
PY
)
      # substitui ${ctx}
      prompt="${prompt//'${ctx}'/${CTX[ctx]:-}}"
      ./gemx.sh gen --prompt "$prompt" || true
      last_out="(stdout capturado externamente)"
      ;;
    obsidian)
      title=$(python3 - <<PY <<<"$steps"
import json,sys; d=json.load(sys.stdin)[$i]; print(d.get('title','Gemx Note'))
PY
)
      ./plugins.d/obsidian_export.sh "$title" "$last_out" || true
      ;;
  esac
  export IDX=$((i+1))
done
echo "[FLOW] pipeline concluído."
