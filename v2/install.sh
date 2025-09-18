#!/usr/bin/env bash
# install.sh — Bootstrap do Gemini Megapack (projeto local)
# Sem set -euo por padrão (idempotente e verboso).

echo "[INFO] Iniciando instalação local do Gemini Megapack..."

proj_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$proj_dir" || exit 1

# --- Funções utilitárias ---
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
need() { command -v "$1" >/dev/null 2>&1; }
say()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err()  { echo "[ERR ] $*" >&2; }

# --- SO / Gerenciador de pacotes ---
uname_s="$(uname -s 2>/dev/null || echo Unknown)"
pkg_mgr=""
if need brew; then pkg_mgr="brew"
elif need apt-get; then pkg_mgr="apt"
elif need dnf; then pkg_mgr="dnf"
elif need pacman; then pkg_mgr="pacman"
fi
say "Sistema: $uname_s | pkg_mgr: ${pkg_mgr:-nenhum}"

# --- Dependências recomendadas: jq, yq (YAML), direnv ---
install_pkg() {
  local name="$1"
  case "$pkg_mgr" in
    brew) brew list --versions "$name" >/dev/null 2>&1 || brew install "$name" ;;
    apt)  sudo apt-get update && sudo apt-get install -y "$name" ;;
    dnf)  sudo dnf install -y "$name" ;;
    pacman) sudo pacman -Sy --noconfirm "$name" ;;
    *) warn "Instale manualmente: $name" ;;
  esac
}

for dep in jq; do
  if ! need "$dep"; then
    say "Instalando dependência: $dep"
    install_pkg "$dep"
  fi
done

# yq é opcional (para YAML nas automations)
if ! need yq; then
  say "Instalando (opcional) yq"
  install_pkg yq || warn "Não consegui instalar yq automaticamente (opcional)."
fi

# direnv para auto-load do ambiente
if ! need direnv; then
  say "Instalando direnv"
  install_pkg direnv || warn "Não consegui instalar direnv automaticamente."
fi

# --- Gemini CLI (login Google, sem API) ---
if ! need gemini && ! need gmini; then
  say "Gemini CLI não encontrado. Tentando instalar..."
  if [ "$pkg_mgr" = "brew" ]; then
    brew install gemini-cli || warn "Falhou via brew; tentando via npm"
  fi
  if ! need gemini && ! need gmini; then
    if need npm; then
      npm i -g @google/gemini-cli || warn "Falhou via npm. Instale manualmente."
    else
      warn "npm não encontrado; instale Node/NPM ou use brew para gemini-cli."
      if [ "$pkg_mgr" = "brew" ]; then
        brew install node || true
        npm i -g @google/gemini-cli || true
      fi
    fi
  fi
fi

# --- Tornar wrapper executável ---
chmod +x "./gemx.sh" 2>/dev/null || true

# --- Direnv hook no .zshrc (idempotente) ---
zshrc="${HOME}/.zshrc"
hook='eval "$(direnv hook zsh)"'
if need direnv; then
  if [ -f "$zshrc" ]; then
    if ! grep -Fq "$hook" "$zshrc" 2>/dev/null; then
      say "Adicionando hook direnv ao ~/.zshrc"
      printf '\n# direnv (Gemini Megapack)\n%s\n' "$hook" >> "$zshrc"
    else
      say "Hook do direnv já presente no ~/.zshrc"
    fi
  else
    say "Criando ~/.zshrc com hook do direnv"
    printf '#!/usr/bin/env zsh\n%s\n' "$hook" > "$zshrc"
  fi
else
  warn "direnv não instalado; pulei hook."
fi

# --- .env/.envrc (já no pacote) ---
if [ ! -f ".env" ]; then
  warn "Arquivo .env não encontrado no pacote (incomum)."
fi
if [ ! -f ".envrc" ]; then
  warn "Arquivo .envrc não encontrado no pacote (incomum)."
fi

# --- direnv allow (se disponível) ---
if need direnv; then
  say "Executando 'direnv allow .'"
  direnv allow . || warn "Falha em 'direnv allow .'. Abra um novo shell e tente novamente."
fi

# --- Mensagens finais ---
say "Instalação local concluída."
echo
echo "Próximos passos:"
echo "  1) Abra um novo terminal OU rode: source ~/.zshrc"
echo "  2) Entre na pasta do projeto (se já não estiver) para ativar o direnv."
echo "  3) Faça login no Gemini CLI (Google):"
echo "       ./gemx.sh login"
echo "  4) Teste:"
echo "       gx   # abre menu"
echo "       gxg --prompt 'Diga OK em pt-br.'"
echo
echo "Se algo falhar, rode:"
echo "  ./doctor.sh"
