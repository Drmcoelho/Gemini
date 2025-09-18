#!/usr/bin/env bash
# gemx.sh — Mega Wrapper Gemini CLI (apenas binário; login Google)
# Compat: macOS bash 3.2+ / Linux bash 4+
# Filosofia: pass-through ao binário oficial, somando UX, menus, automations, others.json e conveniências.
# "Sempre gemini-2.5-pro": por padrão e via GEMX_FORCE_MODEL (override hard).

# --- Modo estrito opcional (off por padrão) ---
if [ -n "${GEMX_STRICT:-}" ]; then
  set -euo pipefail
fi

# ---------- Paths & Config ----------
GEMX_HOME="${GEMX_HOME:-$HOME/.config/gemx}"
GEMX_CFG="$GEMX_HOME/config.json"
GEMX_HIST="${GEMX_HOME}/history"
GEMX_LOGS="${GEMX_HOME}/logs"
GEMX_AUTOS="${GEMX_AUTOS:-./automations}"   # automations do projeto
GEMX_OTHERS="${GEMX_OTHERS:-./others.json}" # catálogo de extensões/plugins/integrações/automations
mkdir -p "$GEMX_HOME" "$GEMX_HIST" "$GEMX_LOGS" "$GEMX_AUTOS"

# --- "sempre gemini-2.5-pro" ---
# Se definido, este valor SOBRESCREVE QUALQUER seleção de modelo.
GEMX_FORCE_MODEL="${GEMX_FORCE_MODEL:-gemini-2.5-pro}"

# ---------- Helpers portáteis ----------
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
now_iso_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
ts_compact()   { date -u +"%Y%m%dT%H%M%SZ"; }
is_tty() { [ -t 1 ]; }
color() { local c="$1"; shift; if is_tty; then printf "\033[%sm%s\033[0m" "$c" "$*"; else printf "%s" "$*"; fi; }
info() { [ "${GEMX_QUIET:-0}" = "1" ] && return 0; echo "$(color 36 "[INFO]") $*" 1>&2; }
warn() { echo "$(color 33 "[WARN]") $*" 1>&2; }
err()  { echo "$(color 31 "[ERR]")  $*" 1>&2; }
need() { command -v "$1" >/dev/null 2>&1; }
confirm() { printf "%s [y/N]: " "$1"; read -r a || return 1; a="$(lower "$a")"; [ "$a" = "y" ] || [ "$a" = "yes" ]; }

audit_enabled(){ [ "$(get_cfg '.plugins.audit_log_jsonl')" = "true" ]; }
audit_log(){
  # Usage: audit_log <event> <bin> <args...>
  audit_enabled || return 0
  local event="$1"; shift
  local bin="$1"; shift
  local ts; ts="$(now_iso_utc)"
  local wd="$PWD"
  local model
  model="$(get_cfg '.model')"
  if [ -n "${GEMX_FORCE_MODEL:-}" ]; then model="$GEMX_FORCE_MODEL"; fi
  # Build argv JSON array
  local argv_json
  argv_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
  # Ensure logs dir
  local lf_dir="$GEMX_LOGS"; mkdir -p "$lf_dir"
  local lf="$lf_dir/audit-$(date -u +%Y%m%d).jsonl"
  jq -cn --arg ts "$ts" --arg event "$event" --arg wd "$wd" --arg bin "$bin" --arg model "$model" --argjson argv "$argv_json" '{ts:$ts,event:$event,wd:$wd,bin:$bin,model:$model,argv:$argv}' >> "$lf"
}

# Confirmação opcional antes de executar comandos (plugin confirm_before_run)
confirm_run(){
  [ "$(get_cfg '.plugins.confirm_before_run')" = "true" ] || return 0
  [ -t 1 ] || return 0
  printf "Confirmar execução? [y/N]: "
  local a; read -r a || return 1
  a="$(lower "$a")"; [ "$a" = "y" ] || [ "$a" = "yes" ]
}

# Execução com suporte a dry-run e auditoria
GEMX_DRYRUN="${GEMX_DRYRUN:-}"
run_cmd(){
  # $1 bin; demais: args
  if [ -n "$GEMX_DRYRUN" ]; then
    echo "[DRY-RUN] $*"
    audit_log "dry-run" "$1" "${@:2}"
    return 0
  fi
  if ! confirm_run; then
    echo "[CANCELADO] $*"
    audit_log "cancel" "$1" "${@:2}"
    return 130
  fi
  audit_log "start" "$1" "${@:2}"
  "$@"; local st=$?
  audit_log "finish" "$1" "${@:2}"
  return $st
}
fzf_others() {
  if [ ! -f "$GEMX_OTHERS" ]; then warn "others.json não encontrado: $GEMX_OTHERS"; return 1; fi
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemoth.XXXXXX")" || return 1
  jq -r '.extensions[]? | "EXT\t\(.id)\t\(.description // "")"' "$GEMX_OTHERS" >> "$tmp"
  jq -r '.plugins[]? | "PLG\t\(.key)\t\(.description // "")"' "$GEMX_OTHERS" >> "$tmp"
  jq -r '.interactions[]? | "INT\t\(.id)\t\(.label // .id)"' "$GEMX_OTHERS" >> "$tmp"
  jq -r '.automations[]? | "AUT\t\(.file)\t\(.description // "")"' "$GEMX_OTHERS" >> "$tmp"

  # Cria script temporário para preview do fzf, evitando problemas de quoting
  local pv_script; pv_script="$(mktemp "${TMPDIR:-/tmp}/gemoth-prev.XXXXXX")" || { rm -f "$tmp"; return 1; }
  cat >"$pv_script" <<'SH'
#!/usr/bin/env bash
set -e
line="$1"
IFS=$'	' read -r t a b <<< "$line"
case "$t" in
  EXT)
    echo "Extensão: $a"; echo
    jq -r --arg id "$a" '.extensions[] | select(.id==$id) | .description' "$GEMX_OTHERS"
    ;;
  PLG)
    echo "Plugin: $a"; echo
    echo "Descrição:"
    jq -r --arg k "$a" '.plugins[] | select(.key==$k) | .description' "$GEMX_OTHERS"
    echo
    val=$(jq -r --arg k "$a" '.plugins[$k]' "$GEMX_CFG")
    echo "Valor atual (config.json): ${val}"
    ;;
  INT)
    echo "Interaction: $a"; echo
    jq -r --arg id "$a" '.interactions[] | select(.id==$id)' "$GEMX_OTHERS"
    echo
    itype=$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .type' "$GEMX_OTHERS")
    if [ "$itype" = "template" ]; then
      key=$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .template_key' "$GEMX_OTHERS")
      echo
      echo "--- template [$key] ---"
      jq -r --arg k "$key" '.templates[$k]' "$GEMX_CFG"
    fi
    ;;
  AUT)
    echo "Automation: $a"; echo
    if [ -f "$a" ]; then sed -n "1,200p" "$a"; else echo "(arquivo não encontrado)"; fi
    ;;
esac
SH
  chmod +x "$pv_script"

  local pick
  if has_fzf; then
    pick="$(cat "$tmp" | GEMX_OTHERS="$GEMX_OTHERS" GEMX_CFG="$GEMX_CFG" fzf --with-nth=1,2,3 --delimiter="\t" --no-mouse --height=90% --reverse --border \
           --preview="GEMX_OTHERS=\"$GEMX_OTHERS\" GEMX_CFG=\"$GEMX_CFG\" bash '$pv_script' {}" --preview-window=right:65%)"
  else
    warn "fzf não instalado. Usando primeira entrada disponível."
    pick="$(head -n1 "$tmp")"
  fi
  rm -f "$tmp" "$pv_script"
  [ -n "$pick" ] || return 0
  local t; t="$(printf "%s" "$pick" | awk -F'\t' '{print $1}')"
  local a; a="$(printf "%s" "$pick" | awk -F'\t' '{print $2}')"
  case "$t" in
    EXT)
      if need gh; then gh extension install "$a"; else warn "gh não instalado."; fi ;;
    PLG)
      set_cfg ".plugins.$a = ( .plugins.$a | not )"; echo "Plugin '$a' agora: $(get_cfg ".plugins.$a")" ;;
    INT)
      local itype; itype="$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .type' "$GEMX_OTHERS")"
      if [ "$itype" = "template" ]; then key="$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .template_key' "$GEMX_OTHERS")"; p="$(jq -r --arg k "$key" '.templates[$k]' "$GEMX_CFG")"; [ -n "$p" ] && gem_gen "$p";
      elif [ "$itype" = "prompt" ]; then p="$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .prompt' "$GEMX_OTHERS")"; [ -n "$p" ] && gem_gen "$p";
      elif [ "$itype" = "automation" ]; then f="$(jq -r --arg id "$a" '.interactions[] | select(.id==$id) | .file' "$GEMX_OTHERS")"; [ -n "$f" ] && auto_run "$f"; fi ;;
    AUT)
      auto_run "$a" ;;
  esac
}
## helpers já definidos acima

# FZF detection and helpers
has_fzf() { command -v fzf >/dev/null 2>&1; }
fzf_select() {
  # $1: comando que lista entradas (uma por linha)
  # $2: comando de preview (opcional) que usa '{}' como placeholder
  local list_cmd="$1" prev_cmd="$2" pick
  if has_fzf; then
    if [ -n "$prev_cmd" ]; then
      pick=$(eval "$list_cmd" | fzf --no-mouse --height=90% --reverse --border \
        --preview "$prev_cmd" --preview-window=right:60%)
    else
      pick=$(eval "$list_cmd" | fzf --no-mouse --height=90% --reverse --border)
    fi
  else
    warn "fzf não instalado; selecionando primeira entrada."
    pick=$(eval "$list_cmd" | head -n1)
  fi
  printf '%s' "$pick"
}

# ---------- Binário, deps e configuração ----------
GEMX_BIN=""
resolve_bin(){
  if [ -n "${GEMINI_BIN:-}" ] && need "$GEMINI_BIN"; then GEMX_BIN="$GEMINI_BIN"; return 0; fi
  if need gemini; then GEMX_BIN="gemini"; return 0; fi
  if need gmini; then GEMX_BIN="gmini"; return 0; fi
  GEMX_BIN=""; return 1
}
ensure_bin(){
  if resolve_bin; then return 0; fi
  warn "Nenhum cliente ('gemini' ou 'gmini') encontrado. Instale via npm ou exporte GEMINI_BIN."
  return 1
}
check_deps(){
  need jq || { err "Dependência obrigatória ausente: jq"; return 1; }
  for opt in yq fzf gh; do need "$opt" || { [ "${GEMX_QUIET:-0}" = "1" ] || warn "Opcional não encontrado: $opt"; }; done
  return 0
}
init_cfg(){
  if [ ! -f "$GEMX_CFG" ]; then
    cat >"$GEMX_CFG" <<'JSON'
{
  "model": "gemini-2.5-pro",
  "temperature": 0.2,
  "system": "",
  "plugins": {
    "image_caption": false,
    "audit_log_jsonl": false,
    "confirm_before_run": false
  },
  "profiles": {
    "draft": {"model": "gemini-2.5-flash", "temperature": 0.7, "system": ""}
  },
  "templates": {
    "rx":       "Formate condutas em tópicos; inclua Apresentação, Diluição, Posologia, Administração, Concentração final, Contraindicações, Interações, Efeitos colaterais, Outras infos.",
    "brief":    "Resuma em 5 bullets conclusivos.",
    "sgarbossa":"Explique critérios de Sgarbossa e útil clinicamente em BRE/MP.",
    "hda":      "Fluxo de suspeita de hemorragia digestiva alta. Estruture triagem, estabilização, exames e conduta."
  }
}
JSON
    info "Config criado em $GEMX_CFG"
  fi
}
get_cfg() { jq -r "$1 // empty" "$GEMX_CFG"; }
set_cfg() {
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemx.XXXXXX")" || { err "mktemp falhou"; return 1; }
  if jq "$1" "$GEMX_CFG" >"$tmp" 2>/dev/null; then mv "$tmp" "$GEMX_CFG"; else rm -f "$tmp"; err "jq set_cfg falhou"; return 1; fi
}

# ---------- Histórico ----------
save_hist() {
  local title="$1" body="$2" ts file
  ts="$(ts_compact)"; file="${GEMX_HIST}/sess_${ts}.md"
  {
    printf "# Gemini Session %s\n\n" "$(now_iso_utc)"
    printf "## Title\n\n%s\n\n" "$title"
    printf "## Body\n\n%s\n" "$body"
  } >"$file"
  echo "$file"
}

# ---------- Prompt acquisition ----------
read_from_editor() {
  local ed="${EDITOR:-vi}" tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemxpr.XXXXXX")" || { err "mktemp falhou"; return 1; }
  cat >"$tmp" <<'EOT'
# Escreva abaixo o prompt. Linhas iniciadas com '#' serão ignoradas.
EOT
  "$ed" "$tmp"
  grep -v '^[[:space:]]*#' "$tmp" | sed '/^[[:space:]]*$/d'
  rm -f "$tmp"
}

# ---------- Core: chamar o binário ----------
gem_exec() {
  if [ -n "${GEMX_DRYRUN:-}" ]; then
    # Em dry-run, não exigimos que o binário exista; usamos um nome padrão para log
    local bin_name="${GEMX_BIN:-gemini}"
    run_cmd "$bin_name" "$@"
    return $?
  fi
  ensure_bin || return 127
  run_cmd "$GEMX_BIN" "$@"
}

# One-shot generate (com sistema/temperatura/modelo/imagens)
gem_gen() {
  # $1 prompt, $2 model, $3 temp (ignorado), $4 system, imagens extras em "$@" (sem suporte no CLI atual)
  local prompt="$1"; shift
  local model="${1:-$(get_cfg '.model')}"; shift || true
  local _temp_unused="${1:-$(get_cfg '.temperature')}"; shift || true
  local system="${1:-$(get_cfg '.system')}"; shift || true

  # Força modelo, se solicitado (padrão: gemini-2.5-pro)
  if [ -n "${GEMX_FORCE_MODEL:-}" ]; then
    model="$GEMX_FORCE_MODEL"
  fi

  # O Gemini CLI atual aceita prompt posicional e -m para modelo; não há --system estável,
  # então prefixamos o prompt com uma linha de sistema se houver.
  if [ -n "$system" ] && [ "$system" != "null" ]; then
    prompt="System: $system

$prompt"
  fi

  local args=( -m "$model" "$prompt" )
  # Imagens extras não são suportadas diretamente; ignoramos "$@" aqui por enquanto.
  gem_exec "${args[@]}"
}

# Chat interativo
gem_chat_loop() {
  ensure_bin || return 1
  local model temp system
  model="$(get_cfg '.model')"; temp="$(get_cfg '.temperature')"; system="$(get_cfg '.system')"
  # Aplica força do modelo
  if [ -n "${GEMX_FORCE_MODEL:-}" ]; then model="$GEMX_FORCE_MODEL"; fi
  info "Chat — model=$model temp=$temp"
  [ -n "$system" ] && echo "$(color 90 "System: $system")"
  while true; do
    printf "\nVocê> "
    local p; read -r p || break
    [ -z "$p" ] && continue
    local full="$p"
    if [ -n "$system" ] && [ "$system" != "null" ]; then
      full="System: $system\n\n$full"
    fi
    gem_exec -m "$model" "$full"
  done
}

# ---------- Models & Project ----------
gem_models_list() {
  gem_exec model list 2>/dev/null || gem_exec models 2>/dev/null || { warn "Subcomando de modelos não encontrado; usando 'help'"; gem_exec --help | sed -n '1,120p'; }
}
gem_set_model() {
  local m="$1"; [ -n "$m" ] || { err "Informe o modelo"; return 1; }
  set_cfg ".model = \"$m\"" && info "Modelo padrão: $m (pode ser sobrescrito por GEMX_FORCE_MODEL=$GEMX_FORCE_MODEL)"
}
gem_project_set() {
  local p="$1"; [ -n "$p" ] || { err "Informe o projeto"; return 1; }
  set_cfg ".project = \"$p\"" && export GOOGLE_CLOUD_PROJECT="$p" && info "Projeto ativo: $p"
}

# ---------- Login/Conta ----------
gem_login()  { gem_exec login 2>/dev/null || gem_exec; }
gem_logout() { gem_exec logout 2>/dev/null || { warn "Sem 'logout'; removendo ~/.gemini"; rm -rf "$HOME/.gemini"; } }
gem_whoami() { gem_exec whoami 2>/dev/null || { warn "Sem 'whoami'; exibindo ~/.gemini"; ls -la "$HOME/.gemini" 2>/dev/null || true; } }

# ---------- Cache (se suportado) ----------
gem_cache_list() { gem_exec cache list 2>/dev/null || warn "cache list não suportado"; }
gem_cache_clear(){ gem_exec cache clear 2>/dev/null || warn "cache clear não suportado"; }

# ---------- Templates/Perfis ----------
tpl_list() { jq -r '.templates | keys[]' "$GEMX_CFG"; }
tpl_show() { local k="$1"; jq -r --arg k "$k" '.templates[$k]' "$GEMX_CFG"; }
profile_apply() {
  local p="$1"; [ -n "$p" ] || { err "Informe o profile"; return 1; }
  if jq -e --arg p "$p" '.profiles[$p]' "$GEMX_CFG" >/dev/null; then
    local expr='.model = .profiles[$p].model // .model | .temperature = .profiles[$p].temperature // .temperature | .system = .profiles[$p].system // .system'
    set_cfg "$expr" --arg p "$p" && info "Profile aplicado: $p (modelo pode ser sobrescrito por GEMX_FORCE_MODEL=$GEMX_FORCE_MODEL)"
  else err "Profile não encontrado: $p"; fi
}

# ---------- Automations ----------
auto_list() {
  find "$GEMX_AUTOS" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.sh' \) | sort
}
auto_show() {
  local f="$1"; [ -f "$f" ] || { err "Arquivo não encontrado: $f"; return 1; }
  echo "----- $f -----"; cat "$f"
}
auto_new_quick() {
  local name="$1"; [ -n "$name" ] || { err "Nome obrigatório"; return 1; }
  local f="${GEMX_AUTOS}/${name}.yaml"
  if [ -e "$f" ]; then err "Já existe: $f"; return 1; fi
  cat >"$f" <<'YAML'
name: exemplo
model: gemini-2.5-pro
temperature: 0.2
prompt: |
  Resuma o texto: {{INPUT}}
extra_args: []
YAML
  info "Criado: $f"
  ${EDITOR:-vi} "$f"
}
auto_run() {
  local spec="$1"; shift || true
  if [ -x "$spec" ] && [ -f "$spec" ]; then
    info "Executando script: $spec"
    "$spec" "$@"
    return $?
  fi
  # Detecta extensão de forma robusta
  local ext="${spec##*.}"
  if [ "$ext" = "yaml" ] || [ "$ext" = "yml" ]; then
    if need yq; then
      local model temp prompt extra_p; model="$(yq -r '.model // "gemini-2.5-pro"' "$spec")"
      temp="$(yq -r '.temperature // 0.2' "$spec")"
      prompt="$(yq -r '.prompt' "$spec")"
      extra_p="${GEMX_PROMPT:-}"
      if [ -n "$extra_p" ]; then
        if printf "%s" "$prompt" | grep -q '{{INPUT}}'; then
          prompt="$(printf "%s" "$prompt" | sed "s/{{INPUT}}/$(printf '%s' "$extra_p" | sed 's:[\\&/:]:\\&:g')/")"
        else
          prompt="${prompt}

---
User input:
${extra_p}"
        fi
      fi
      [ -z "$prompt" ] && { err "prompt vazio"; return 1; }
      gem_gen "$prompt" "$model" "$temp" "" "$@"
    else
      err "yq não instalado para YAML"; return 1
    fi
    return
  fi
  if [ "$ext" = "json" ]; then
    local model temp prompt extra_p
    model="$(jq -r '.model // "gemini-2.5-pro"' "$spec")"
    temp="$(jq -r '.temperature // 0.2' "$spec")"
    prompt="$(jq -r '.prompt' "$spec")"
    extra_p="${GEMX_PROMPT:-}"
    if [ -n "$extra_p" ]; then
      if printf "%s" "$prompt" | grep -q '{{INPUT}}'; then
        prompt="$(printf "%s" "$prompt" | sed "s/{{INPUT}}/$(printf '%s' "$extra_p" | sed 's:[\\&/:]:\\&:g')/")"
      else
        prompt="${prompt}

---
User input:
${extra_p}"
      fi
    fi
    [ -z "$prompt" ] && { err "prompt vazio"; return 1; }
    gem_gen "$prompt" "$model" "$temp" "" "$@"
    return
  fi
  err "Formato não suportado: $spec"
  return 1
}

# ---------- Others.json (extensões/plugins/integrações/automations) ----------
others_menu() {
  if [ ! -f "$GEMX_OTHERS" ]; then
    warn "others.json não encontrado em $GEMX_OTHERS"; return 1
  fi
  while true; do
    echo
    echo "$(color 35 '[OTHERS]') Catálogo:"
    echo "  1) Extensões (install)"
    echo "  2) Plugins (toggle -> config.json)"
    echo "  3) Interações (roda prompts/templates)"
    echo "  4) Automations (run)"
    echo "  5) Voltar"
    printf "> "
    read -r op
    case "$op" in
      1)
        if ! need gh; then warn "GitHub CLI (gh) não instalado"; continue; fi
        # Lista extensões e permite instalar
        jq -r '.extensions[]? | "\(.id)\t\(.description)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para instalar (Enter para voltar): "
        read -r n; [ -z "$n" ] && continue
        id="$(jq -r --argjson n "$n" '.extensions[$n-1].id' "$GEMX_OTHERS" 2>/dev/null)"
        [ -z "$id" ] || gh extension install "$id"
        ;;
      2)
        # Plugins: chave -> toggle boolean em config.json
        jq -r '.plugins[]? | "\(.key)\t\(.description)\t(default:\(.default))"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para alternar plugin (Enter para voltar): "
        read -r n; [ -z "$n" ] && continue
        key="$(jq -r --argjson n "$n" '.plugins[$n-1].key' "$GEMX_OTHERS" 2>/dev/null)"
        [ -z "$key" ] || set_cfg ".plugins.$key = ( .plugins.$key | not )"
        echo "Plugin '$key' agora: $(get_cfg ".plugins.$key")"
        ;;
      3)
        # Interações: template/prompt predefinido
        jq -r '.interactions[]? | "\(.id)\t\(.label)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # (Enter p/ voltar): "
        read -r n; [ -z "$n" ] && continue
        type="$(jq -r --argjson n "$n" '.interactions[$n-1].type' "$GEMX_OTHERS")"
        case "$type" in
          template)
            key="$(jq -r --argjson n "$n" '.interactions[$n-1].template_key' "$GEMX_OTHERS")"
            prompt="$(jq -r --arg k "$key" '.templates[$k]' "$GEMX_CFG")"
            [ -z "$prompt" ] && { err "template '$key' não encontrado em config.json"; continue; }
            gem_gen "$prompt"
            ;;
          prompt)
            p="$(jq -r --argjson n "$n" '.interactions[$n-1].prompt' "$GEMX_OTHERS")"
            gem_gen "$p"
            ;;
          automation)
            f="$(jq -r --argjson n "$n" '.interactions[$n-1].file' "$GEMX_OTHERS")"
            auto_run "$f"
            ;;
          *)
            err "tipo desconhecido";;
        esac
        ;;
      4)
        # Automations cadastradas no others.json
        jq -r '.automations[]? | "\(.file)\t\(.description)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para rodar (Enter p/ voltar): "
        read -r n; [ -z "$n" ] && continue
        f="$(jq -r --argjson n "$n" '.automations[$n-1].file' "$GEMX_OTHERS")"
        auto_run "$f"
        ;;
      5) return 0 ;;
    esac
  done
}


# ---------- FZF-centered pickers ----------
fzf_hist() {
  local dir="$GEMX_HIST"
  [ -d "$dir" ] || { warn "Sem histórico em $dir"; return 1; }
  local cmd="ls -1t $dir/sess_*.md 2>/dev/null"
  local prev='[ -f {} ] && (echo {} && echo "-----" && sed -n "1,120p" {} )'
  local pick="$(fzf_select "$cmd" "$prev")"
  [ -n "$pick" ] && ${PAGER:-less} "$pick"
}

fzf_auto() {
  local dir="$GEMX_AUTOS"
  [ -d "$dir" ] || { warn "Sem automations em $dir"; return 1; }
  local cmd="ls -1 $dir/*.{yaml,yml,json,sh} 2>/dev/null || ls -1 $dir/* 2>/dev/null"
  local prev='[ -f {} ] && (echo {} && echo "-----" && sed -n "1,200p" {} )'
  local pick="$(fzf_select "$cmd" "$prev")"
  [ -n "$pick" ] && auto_run "$pick"
}

fzf_tpl() {
  local keys="$(jq -r '.templates | keys[]' "$GEMX_CFG" 2>/dev/null)"
  if [ -z "$keys" ]; then warn "Sem templates no config."; return 1; fi
  local tmp="$(mktemp "${TMPDIR:-/tmp}/gemtpl.XXXXXX")" || return 1
  printf "%s\n" "$keys" > "$tmp"
  local prev='jq -r --arg k {1} ".templates[$k]" '"$GEMX_CFG"' 2>/dev/null | sed -n "1,80p"'
  # fzf does not natively do variable substitution in preview; hack: use awk to print the key and then call jq
  local pick="$(cat "$tmp" | fzf --no-mouse --height=90% --reverse --border --preview-window=right:60% --preview "k={}; jq -r --arg k \"$k\" '.templates[$k]' $GEMX_CFG 2>/dev/null | sed -n '1,120p'")"
  rm -f "$tmp"
  [ -n "$pick" ] || return 1
  local prompt="$(jq -r --arg k "$pick" '.templates[$k]' "$GEMX_CFG")"
  [ -n "$prompt" ] && gem_gen "$prompt"
}

fzf_models() {
  # capture models list; try multiple commands
  local out="$( (gem_exec model list 2>/dev/null || gem_exec models 2>/dev/null) | sed -n '1,200p' )"
  if [ -z "$out" ]; then warn "Não consegui listar modelos; use 'models'."; return 1; fi
  local tmp="$(mktemp "${TMPDIR:-/tmp}/gemmdl.XXXXXX")" || return 1
  printf "%s\n" "$out" > "$tmp"
  local pick="$(cat "$tmp" | fzf --no-mouse --height=90% --reverse --border)"
  rm -f "$tmp"
  # tenta extrair o primeiro campo alfanumérico como nome do modelo
  local m="$(printf "%s" "$pick" | awk '{print $1}')"
  [ -n "$m" ] && gem_set_model "$m"
}

## fzf_others já definido acima com preview via script (mantido apenas uma vez)


# ---------- Menu ----------
menu() {
  while true; do
    echo
    echo "$(color 35 '[GEMX]') Selecione:"
    echo "  1) Setup/Deps & Binário"
    echo "  2) Login / Whoami / Logout"
    echo "  3) Modelos & Projeto"
    echo "  4) Chat (interativo)"
    echo "  5) Geração (prompt único)"
    echo "  6) Visão (imagem + prompt)"
    echo "  7) Templates & Perfis"
    echo "  8) Automations (ls/new/show/run)"
    echo "  9) Others.json (extensões/plugins/interações)"
    echo " 10) Cache"
    echo " 11) CI helper"
    echo " 12) Pass-through (args livres p/ gemini)"
    echo " 13) FZF Center (hist/auto/others/tpl/models)"
    echo " 14) Sair"
    printf "> "
    read -r op
    case "$op" in
      1) check_deps; ensure_bin || true ;;
      2)
        echo "  a) login   b) whoami   c) logout"
        printf "> "; read -r s
        case "$s" in
          a) gem_login ;;
          b) gem_whoami ;;
          c) gem_logout ;;
        esac
        ;;
      3)
        echo "  a) listar modelos   b) set modelo   c) set projeto"
        printf "> "; read -r s
        case "$s" in
          a) gem_models_list ;;
          b) printf "Modelo> "; read -r m; [ -n "$m" ] && gem_set_model "$m" ;;
          c) printf "Projeto> "; read -r p; [ -n "$p" ] && gem_project_set "$p" ;;
        esac
        ;;
      4) gem_chat_loop ;;
      5)
        local p m t sys
        echo "PROMPT (linha única; vazio abre editor)"; printf "> "; read -r p
        [ -z "$p" ] && p="$(read_from_editor)"
        [ -z "$p" ] && { warn "Prompt vazio"; continue; }
        printf "Modelo [Enter=cfg/forçado=%s]: " "$GEMX_FORCE_MODEL"; read -r m
        printf "Temp   [Enter=cfg]: "; read -r t
        printf "System [Enter=cfg]: "; read -r sys
        gem_gen "$p" "${m:-$(get_cfg '.model')}" "${t:-$(get_cfg '.temperature')}" "${sys:-$(get_cfg '.system')}"
        ;;
      6)
        local p img
        printf "Caminho da imagem: "; read -r img
        [ -f "$img" ] || { err "Imagem não existe"; continue; }
        echo "PROMPT (linha; vazio abre editor)"; printf "> "; read -r p
        [ -z "$p" ] && p="$(read_from_editor)"
        [ -z "$p" ] && { warn "Prompt vazio"; continue; }
        gem_gen "$p" "" "" "" "$img"
        ;;
      7)
        echo "  a) listar templates   b) ver template   c) aplicar profile"
        printf "> "; read -r s
        case "$s" in
          a) tpl_list ;;
          b) printf "Template key> "; read -r k; tpl_show "$k" ;;
          c) printf "Profile key> "; read -r k; profile_apply "$k" ;;
        esac
        ;;
      8)
        echo "  a) listar   b) novo   c) show   d) run"
        printf "> "; read -r s
        case "$s" in
          a) auto_list ;;
          b) printf "Nome> "; read -r n; auto_new_quick "$n" ;;
          c) printf "Arquivo> "; read -r f; auto_show "$f" ;;
          d) printf "Arquivo> "; read -r f; auto_run "$f" ;;
        esac
        ;;
      9) others_menu ;;
      10)
        echo "  a) cache list   b) cache clear"
        printf "> "; read -r s
        case "$s" in
          a) gem_cache_list ;;
          b) confirm "Limpar cache? " && gem_cache_clear ;;
        esac
        ;;
      11)
        cat <<'YML'
# Exemplo de step em GitHub Actions (sem API key; usa binário no runner)
- name: Gemini one-shot
  run: |
    ./gemx.sh gen --prompt "Diga 'ok' em pt-br."
YML
        ;;
      12)
        echo "Digite os argumentos exatos p/ gemini, ex: 'model list' ou 'generate --help'"
        printf "gemini "; read -r rest
        gem_exec $rest
        ;;
      13)
        echo "  a) history   b) automations   c) others   d) templates   e) models"
        printf "> "; read -r z
        case "$z" in
          a) fzf_hist ;;
          b) fzf_auto ;;
          c) fzf_others ;;
          d) fzf_tpl ;;
          e) fzf_models ;;
        esac
        ;;
      14) exit 0 ;;
    esac
  done
}

# ---------- CLI flags do wrapper ----------
usage() {
  cat <<'HLP'
Uso: ./gemx.sh <comando> [opções]

Comandos principais:
  menu                         Abre menu interativo
  setup                        Verifica deps e binário
  login|whoami|logout          Conta (Google login)
  models [set <MODEL>]         Lista ou define modelo (pode ser sobrescrito por GEMX_FORCE_MODEL)
  project set <ID>             Define GOOGLE_CLOUD_PROJECT
  chat                         Chat interativo
  gen [opções]                 Geração one-shot
  vision --image PATH [opções] Geração com imagem
  tpl ls|show <KEY>            Templates
  profile apply <NAME>         Aplica perfil
  auto ls|new <NAME>|show <F>|run <F>  Automations
  others                       Abre o menu others.json
  cache ls|clear               Cache (se suportado)
  passthrough -- ...           Encaminha tudo ao binário
  help                         Ajuda

Flags globais:
  --dry-run                    Não executa; apenas imprime o comando repassado ao CLI

Opções gen/vision comuns:
  --prompt "..." | --prompt-file F | --editor
  --model NAME
  --temp N.N
  --system "mensagem"
  --                        (tudo após -- vai direto pro binário, ex.: --max-output-tokens 2048)
HLP
}

# ---------- Parser simples ----------
DRY=""; for a in "$@"; do [ "$a" = "--dry-run" ] && DRY=1; done; [ -n "$DRY" ] && export GEMX_DRYRUN=1
cmd="$1" 2>/dev/null || cmd="menu"

init_cfg; check_deps || true

case "$cmd" in
  help|-h|--help) usage ;;
  menu) menu ;;
  setup) check_deps; ensure_bin ;;
  login) gem_login ;;
  whoami) gem_whoami ;;
  logout) gem_logout ;;
  models)
    sub="$2" 2>/dev/null || sub=""
    case "$sub" in
      set) m="$3"; [ -n "$m" ] || { err "Informe modelo"; exit 1; }; gem_set_model "$m" ;;
      *) gem_models_list ;;
    esac
    ;;
  project)
    [ "${2:-}" = "set" ] || { err "Use: project set <ID>"; exit 1; }
    gem_project_set "${3:-}"
    ;;
  chat) gem_chat_loop ;;
  gen)
    shift
    MODEL=""; TEMP=""; SYSTEM=""; PROMPT=""; PROMPT_FILE=""; USE_EDITOR=0; IMGS=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --temp) TEMP="$2"; shift 2 ;;
        --system) SYSTEM="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        --editor) USE_EDITOR=1; shift ;;
        --image) IMGS+=("$2"); shift 2 ;;
        --) shift; break ;;
        *) break ;;
      esac
    done
    if [ -z "$PROMPT" ] && [ -z "$PROMPT_FILE" ] && [ $USE_EDITOR -eq 0 ] && [ ! -t 0 ]; then
      PROMPT="$(cat)"
    fi
    [ -z "$PROMPT" ] && [ -n "$PROMPT_FILE" ] && PROMPT="$(cat "$PROMPT_FILE" 2>/dev/null || true)"
    [ -z "$PROMPT" ] && [ $USE_EDITOR -eq 1 ] && PROMPT="$(read_from_editor)"
    [ -z "$PROMPT" ] && { err "Prompt vazio"; exit 1; }
    gem_gen "$PROMPT" "${MODEL:-$(get_cfg '.model')}" "${TEMP:-$(get_cfg '.temperature')}" "${SYSTEM:-$(get_cfg '.system')}" "${IMGS[@]}" "$@"
    ;;
  vision)
    shift
    IMG=""; MODEL=""; TEMP=""; SYSTEM=""; PROMPT=""; PROMPT_FILE=""; USE_EDITOR=0
    while [ $# -gt 0 ]; do
      case "$1" in
        --image) IMG="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --temp) TEMP="$2"; shift 2 ;;
        --system) SYSTEM="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        --editor) USE_EDITOR=1; shift ;;
        --) shift; break ;;
        *) break ;;
      esac
    done
    [ -f "$IMG" ] || { err "Imagem não encontrada"; exit 1; }
    if [ -z "$PROMPT" ] && [ -z "$PROMPT_FILE" ] && [ $USE_EDITOR -eq 0 ]; then
      echo "PROMPT (vazio abre editor)"; printf "> "; read -r PROMPT
      [ -z "$PROMPT" ] && PROMPT="$(read_from_editor)"
    fi
    [ -z "$PROMPT" ] && [ -n "$PROMPT_FILE" ] && PROMPT="$(cat "$PROMPT_FILE" 2>/dev/null || true)"
    [ -z "$PROMPT" ] && { err "Prompt vazio"; exit 1; }
    gem_gen "$PROMPT" "${MODEL:-$(get_cfg '.model')}" "${TEMP:-$(get_cfg '.temperature')}" "${SYSTEM:-$(get_cfg '.system')}" "$IMG" "$@"
    ;;
  tpl)
    case "${2:-}" in
      ls) tpl_list ;;
      show) tpl_show "${3:-}" ;;
      *) err "Use: tpl ls | tpl show <KEY>"; exit 1 ;;
    esac
    ;;
  profile)
    [ "${2:-}" = "apply" ] || { err "Use: profile apply <NAME>"; exit 1; }
    profile_apply "${3:-}"
    ;;
  auto)
    case "${2:-}" in
      ls) auto_list ;;
      new) auto_new_quick "${3:-}" ;;
      show) auto_show "${3:-}" ;;
      run) auto_run "${3:-}" ;;
      *) err "Use: auto ls|new <NAME>|show <FILE>|run <FILE>"; exit 1 ;;
    esac
    ;;
  others) others_menu ;;
  cache)
    case "${2:-}" in
      ls) gem_cache_list ;;
      clear) gem_cache_clear ;;
      *) err "Use: cache ls|clear"; exit 1 ;;
    esac
    ;;
  passthrough)
    shift
    [ "${1:-}" = "--" ] && shift
    ensure_bin || exit 127
    gem_exec "$@"
    ;;
  *)
    usage; exit 1 ;;
esac
