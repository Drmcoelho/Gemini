#!/usr/bin/env bash
# install-macos.sh — Setup focado em macOS (Homebrew-only)
echo "[INFO] Setup macOS (Homebrew-only)"

need(){ command -v "$1" >/dev/null 2>&1; }

# Homebrew
if ! need brew; then
  echo "[ERR ] Homebrew não encontrado. Instale via https://brew.sh/"
  exit 1
fi

# Dependências
brew list --versions jq >/dev/null 2>&1 || brew install jq
brew list --versions yq >/dev/null 2>&1 || brew install yq
brew list --versions direnv >/dev/null 2>&1 || brew install direnv
brew list --cask >/dev/null 2>&1 # noop

# Gemini CLI
if ! need gemini && ! need gmini; then
  brew install gemini-cli || {
    echo "[WARN] gemini-cli via brew falhou; tentando via npm"
    brew list --versions node >/dev/null 2>&1 || brew install node
    npm i -g @google/gemini-cli || {
      echo "[ERR ] Não foi possível instalar gemini-cli. Instale manualmente."
    }
  }
fi

# Hook do direnv
zshrc="${HOME}/.zshrc"
hook='eval "$(direnv hook zsh)"'
if [ -f "$zshrc" ]; then
  grep -Fq "$hook" "$zshrc" || printf '\n# direnv (Gemini Megapack)\n%s\n' "$hook" >> "$zshrc"
else
  printf '#!/usr/bin/env zsh\n%s\n' "$hook" > "$zshrc"
fi

# Ativar no projeto
if command -v direnv >/dev/null 2>&1; then
  direnv allow . || true
fi

echo "[INFO] macOS pronto. Login:"
echo "  ./gemx.sh login"
