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
GEMX_AUTOS="${GEMX_AUTOS:-./automations}"   # automations do projeto
GEMX_OTHERS="${GEMX_OTHERS:-./others.json}" # catálogo de extensões/plugins/integrações/automations
mkdir -p "$GEMX_HOME" "$GEMX_HIST" "$GEMX_AUTOS"

# --- "sempre gemini-2.5-pro" ---
# Se definido, este valor SOBRESCREVE QUALQUER seleção de modelo.
GEMX_FORCE_MODEL="${GEMX_FORCE_MODEL:-gemini-2.5-pro}"

# ---------- Helpers portáteis ----------
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
now_iso_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
ts_compact()   { date -u +"%Y%m%dT%H%M%SZ"; }
is_tty() { [ -t 1 ]; }
color() { local c="$1"; shift; if is_tty; then printf "\033[%sm%s\033[0m" "$c" "$*"; else printf "%s" "$*"; fi; }
info() { echo "$(color 36 "[INFO]") $*"; }
warn() { echo "$(color 33 "[WARN]") $*"; }
err()  { echo "$(color 31 "[ERR]")  $*" 1>&2; }
need() { command -v "$1" >/dev/null 2>&1; }
confirm() { printf "%s [y/N]: " "$1"; read -r a || return 1; a="$(lower "$a")"; [ "$a" = "y" ] || [ "$a" = "yes" ]; }

# ---------- FZF helpers (opcional) ----------
has_fzf() { command -v fzf >/dev/null 2>&1; }
fzf_select() {
  # $1: comando que lista entradas; $2: comando preview (opcional)
  local list_cmd="$1" prev_cmd="$2" pick
  if has_fzf; then
    if [ -n "$prev_cmd" ]; then
      pick=$(eval "$list_cmd" | fzf --no-mouse --height=90% --reverse --border \
        --preview "$prev_cmd" --preview-window=right:60%)
    else
      pick=$(eval "$list_cmd" | fzf --no-mouse --height=90% --reverse --border)
    fi
  else
    pick=$(eval "$list_cmd" | head -n1)
  fi
  printf '%s' "$pick"
}

# ---------- Binário (Google login; sem API) ----------
# Ordem: GEMINI_BIN > gemini > gmini
GEMX_BIN=""
resolve_bin() {
  if [ -n "${GEMINI_BIN:-}" ] && need "$GEMINI_BIN"; then GEMX_BIN="$GEMINI_BIN"; return 0; fi
  if need gemini; then GEMX_BIN="gemini"; return 0; fi
  if need gmini;  then GEMX_BIN="gmini";  return 0; fi
  GEMX_BIN=""; return 1
}
ensure_bin() {
  if resolve_bin; then return 0; fi
  warn "Nenhum cliente ('gemini' ou 'gmini') encontrado. Instale e/ou exporte GEMINI_BIN."
  return 1
}

# ---------- Depêndencias sugeridas ----------
check_deps() {
  local miss=0
  for b in jq; do
    if ! need "$b"; then err "Dependência ausente: $b"; miss=1; fi
  done
  [ $miss -eq 0 ] || { warn "Instale as dependências acima e rode novamente."; return 1; }
  return 0
}

# ---------- Config (JSON) ----------
init_cfg() {
  if [ ! -f "$GEMX_CFG" ]; then
    mkdir -p "$(dirname "$GEMX_CFG")"
    cat >"$GEMX_CFG" <<'JSON'
{
  "model": "gemini-2.5-pro",
  "stream": true,
  "temperature": 0.2,
  "max_output_tokens": null,
  "system": "",
  "project": "",
  "plugins": {
    "web_fetch": false,
    "image_caption": false
  },
  "profiles": {
    "med":   {"model": "gemini-2.5-pro", "temperature": 0.1, "system": "Você é um assistente médico objetivo e pragmático."},
    "code":  {"model": "gemini-2.5-pro", "temperature": 0.2, "system": "Você é um pair-programmer pragmático."},
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
    local bin_name="${GEMX_BIN:-gemini}"
    echo "[DRY-RUN] $bin_name $*"
    return 0
  fi
  ensure_bin || return 127
  "$GEMX_BIN" "$@"
}

# One-shot generate (com sistema/temperatura/modelo/imagens)
gem_gen() {
  # $1 prompt, $2 model, $3 temp, $4 system, imagens extras em "$@"
  local prompt="$1"; shift
  local model="${1:-$(get_cfg '.model')}"; shift || true
  local temp="${1:-$(get_cfg '.temperature')}"; shift || true
  local system="${1:-$(get_cfg '.system')}"; shift || true

  # Força modelo, se solicitado (padrão: gemini-2.5-pro)
  if [ -n "${GEMX_FORCE_MODEL:-}" ]; then
    model="$GEMX_FORCE_MODEL"
  fi

  local args=( generate --model "$model" --temperature "$temp" --prompt "$prompt" )
  [ -n "$system" ] && [ "$system" != "null" ] && [ "$system" != "" ] && args+=( --system "$system" )

  while [ $# -gt 0 ]; do
    if [ -f "$1" ]; then args+=( --image "$1" ); shift; else break; fi
  done
  [ $# -gt 0 ] && args+=( "$@" )
  gem_exec "${args[@]}"
}

# Chat interativo
gem_chat_loop() {
  if [ -z "${GEMX_DRYRUN:-}" ]; then
    ensure_bin || return 1
  fi
  local model temp system histf title
  model="$(get_cfg '.model')"; temp="$(get_cfg '.temperature')"; system="$(get_cfg '.system')"
  [ -n "${GEMX_FORCE_MODEL:-}" ] && model="$GEMX_FORCE_MODEL"
  title="Chat $(now_iso_utc)"
  histf="${GEMX_HIST}/chat_$(ts_compact).md"
  {
    printf "# %s\n\n" "$title"
    [ -n "$system" ] && printf "System: %s\n\n" "$system"
  } > "$histf"
  info "Chat — model=$model temp=$temp (hist: $histf)"; echo
  echo "Dicas: :q sair | :help ajuda | :model M | :temp N | :sys (edita) | :save título | :edit abre editor"
  while true; do
    printf "Você> "
    local p; IFS= read -r p || break
    case "$p" in
      :q|:quit) break ;;
      :help)
        echo ":model gemini-2.5-pro | :temp 0.2 | :sys (edita) | :save TÍTULO | :edit (abre editor)"; continue ;;
      :edit)
        p="$(read_from_editor)"; [ -z "$p" ] && continue ;;
      :sys)
        edit_system_msg; system="$(get_cfg '.system')"; continue ;;
      :model*)
        set -- $p; shift; if [ -n "$1" ]; then model="$1"; gem_set_model "$model"; else m="$(pick_model)"; [ -n "$m" ] && { model="$m"; gem_set_model "$model"; }; fi; echo "model=$model"; continue ;;
      :temp*)
        set -- $p; shift; [ -n "$1" ] && { temp="$1"; set_cfg ".temperature = $temp"; echo "temp=$temp"; }; continue ;;
      :save*)
        set -- $p; shift; title="${*:-$title}"; save_hist "$title" "$(cat "$histf")" >/dev/null; info "Sessão salva."; continue ;;
    esac
    [ -z "$p" ] && continue
    printf "\n## Você\n%s\n\n" "$p" >> "$histf"
    { gem_exec chat --model "$model" --temperature "$temp" ${system:+--system "$system"} --prompt "$p" 2>/dev/null \
      || gem_exec generate --model "$model" --temperature "$temp" ${system:+--system "$system"} --prompt "$p"; } | tee -a "$histf"
    printf "\n\n" >> "$histf"
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

# Captura lista de modelos em arquivo temporário para escolha
known_models() {
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemmdl.XXXXXX")" || return 1
  # tenta do CLI apenas se não for dry-run e se houver binário
  if [ -z "${GEMX_DRYRUN:-}" ] && resolve_bin; then
    local out
    out="$( ("$GEMX_BIN" model list 2>/dev/null || "$GEMX_BIN" models 2>/dev/null) | sed -n '1,200p' )"
    if [ -n "$out" ]; then
      printf "%s\n" "$out" > "$tmp"
    fi
  fi
  if [ ! -s "$tmp" ]; then
    # fallback: usa config atual, perfis, e alguns modelos comuns
    local cur profile_mdls
    cur="$(get_cfg '.model')"; [ -n "$cur" ] && printf "%s\n" "$cur" >> "$tmp"
    profile_mdls="$(jq -r '.profiles | to_entries[]?.value.model' "$GEMX_CFG" 2>/dev/null | sed '/^$/d' | sort -u)"
    [ -n "$profile_mdls" ] && printf "%s\n" "$profile_mdls" >> "$tmp"
    printf "%s\n" "gemini-2.5-pro" "gemini-2.5-flash" >> "$tmp"
    sort -u "$tmp" -o "$tmp"
  fi
  echo "$tmp"
}
pick_model() {
  local tmp; tmp="$(known_models)" || return 1
  local pick; pick="$(fzf_select "cat $tmp" "sed -n '1,200p' {}")"
  rm -f "$tmp"
  [ -z "$pick" ] && return 1
  local m; m="$(printf "%s" "$pick" | awk '{print $1}')"
  [ -n "$m" ] && echo "$m"
}
pick_project() {
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemprj.XXXXXX")" || return 1
  if need gcloud; then
    gcloud projects list --format="table(projectId,name)" 2>/dev/null | sed '1d' > "$tmp" || true
  fi
  # fallback: usa valor atual e variável de ambiente
  { get_cfg '.project' | sed '/^$/d'; printf "%s\n" "$GOOGLE_CLOUD_PROJECT"; } | sed '/^$/d' | sort -u >> "$tmp"
  local pick; pick="$(fzf_select "cat $tmp" "sed -n '1,200p' {}")"
  rm -f "$tmp"
  [ -z "$pick" ] && return 1
  local p; p="$(printf "%s" "$pick" | awk '{print $1}')"
  [ -n "$p" ] && echo "$p"
}
edit_system_msg() {
  local cur; cur="$(get_cfg '.system')"
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/gemsys.XXXXXX")" || return 1
  printf "%s\n" "$cur" > "$tmp"
  ${EDITOR:-vi} "$tmp"
  local new; new="$(cat "$tmp")"; rm -f "$tmp"
  set_cfg ".system = \$new" --arg new "$new"
  info "System message atualizado."
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
  if echo "$spec" | grep -E '\.(yaml|yml)$' >/dev/null 2>&1; then
    if need yq; then
      local model temp prompt; model="$(yq -r '.model // "gemini-2.5-pro"' "$spec")"
      temp="$(yq -r '.temperature // 0.2' "$spec")"
      prompt="$(yq -r '.prompt' "$spec")"
      [ -z "$prompt" ] && { err "prompt vazio"; return 1; }
      gem_gen "$prompt" "$model" "$temp" "" "$@"
    else
      err "yq não instalado para YAML"; return 1
    fi
    return
  fi
  if echo "$spec" | grep -E '\.json$' >/dev/null 2>&1; then
    local model temp prompt; model="$(jq -r '.model // "gemini-2.5-pro"' "$spec")"
    temp="$(jq -r '.temperature // 0.2' "$spec")"
    prompt="$(jq -r '.prompt' "$spec")"
    [ -z "$prompt" ] && { err "prompt vazio"; return 1; }
    gem_gen "$prompt" "$model" "$temp" "" "$@"
    return
  fi
  err "Formato não suportado: $spec"
}

# ---------- Others.json (extensões/plugins/integrações/automations) ----------
others_menu() {
  if [ ! -f "$GEMX_OTHERS" ]; then
    warn "others.json não encontrado em $GEMX_OTHERS"; return 1
  fi
  while true; do
    echo
    echo "$(color 35 '[OTHERS]') Catálogo v2:"
    echo "  1) Extensões (install)"
    echo "  2) Plugins (toggle)"
    echo "  3) Ações (run)"
    echo "  4) Recursos (view)"
    echo "  5) Voltar"
    printf "> "
    read -r op
    case "$op" in
      1)
        if ! need gh; then warn "GitHub CLI (gh) não instalado"; continue; fi
        jq -r '.extensions[]? | "\(.id)\t\(.description)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para instalar (Enter para voltar): "
        read -r n; [ -z "$n" ] && continue
        id="$(jq -r --argjson n "$n" '.extensions[$n-1].id' "$GEMX_OTHERS" 2>/dev/null)"
        [ -z "$id" ] || gh extension install "$id"
        ;;
      2)
        jq -r '.plugins[]? | "\(.key)\t\(.description)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para alternar plugin (Enter para voltar): "
        read -r n; [ -z "$n" ] && continue
        key="$(jq -r --argjson n "$n" '.plugins[$n-1].key' "$GEMX_OTHERS" 2>/dev/null)"
        [ -z "$key" ] && continue
        set_cfg ".plugins.$key = ( .plugins.$key | not )"
        echo "Plugin '$key' agora: $(get_cfg ".plugins.$key")"
        ;;
      3)
        jq -r '.actions[]? | "\(.label)\t| \(.type) | tags: \(.tags | join(\", \"))"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para executar (Enter p/ voltar): "
        read -r n; [ -z "$n" ] && continue
        
        action_json="$(jq -r --argjson n "$n" '.actions[$n-1]' "$GEMX_OTHERS" 2>/dev/null)"
        [ -z "$action_json" ] && { err "Ação inválida"; continue; }

        type="$(echo "$action_json" | jq -r '.type')"
        
        case "$type" in
          template)
            key="$(echo "$action_json" | jq -r '.template_key')"
            prompt="$(jq -r --arg k "$key" '.templates[$k]' "$GEMX_CFG")"
            [ -z "$prompt" ] && { err "Template '$key' não encontrado em config.json"; continue; }
            gem_gen "$prompt"
            ;;
          prompt)
            p="$(echo "$action_json" | jq -r '.prompt')"
            # Handle dynamic content like git diff
            if echo "$p" | grep -q '$(git diff --staged)'; then
                staged_diff="$(git diff --staged)"
                if [ -z "$staged_diff" ]; then
                    warn "Nenhuma mudança no stage. O prompt pode ficar vazio."
                fi
                p="$(echo "$p" | sed "s|\\\$(git diff --staged)|$staged_diff|")"
            fi
            gem_gen "$p"
            ;;
          automation)
            f="$(echo "$action_json" | jq -r '.file')"
            auto_run "$f"
            ;;
          shell)
            cmd="$(echo "$action_json" | jq -r '.command')"
            info "Executando: $cmd"
            eval "$cmd"
            ;;
          *)
            err "Tipo de ação desconhecido: $type";;
        esac
        ;;
      4)
        jq -r '.resources[]? | "\(.description)\t| \(.url)"' "$GEMX_OTHERS" | nl -ba
        printf "Selecione # para ver a URL (Enter para voltar): "
        read -r n; [ -z "$n" ] && continue
        url="$(jq -r --argjson n "$n" '.resources[$n-1].url' "$GEMX_OTHERS" 2>/dev/null)"
        [ -n "$url" ] && info "URL: $url"
        ;;
      5) return 0 ;;
    esac
  done
}

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
    echo " 13) Sair"
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
        echo "  a) ver cfg   b) listar modelos   c) escolher modelo   d) set projeto   e) editar system   f) aplicar profile"
        printf "> "; read -r s
        case "$s" in
          a) jq . "$GEMX_CFG" | sed -n '1,200p' ;;
          b) gem_models_list ;;
          c)
            m="$(pick_model)"; if [ -z "$m" ]; then printf "Modelo> "; read -r m; fi; [ -n "$m" ] && gem_set_model "$m" ;;
          d)
            p="$(pick_project)"; if [ -z "$p" ]; then printf "Projeto> "; read -r p; fi; [ -n "$p" ] && gem_project_set "$p" ;;
          e) edit_system_msg ;;
          f) printf "Profile key> "; read -r k; [ -n "$k" ] && profile_apply "$k" ;;
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
      13) exit 0 ;;
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
      pick)
        m="$(pick_model)"; [ -n "$m" ] || { warn "Nenhum modelo selecionado"; exit 1; }
        gem_set_model "$m" ;;
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
