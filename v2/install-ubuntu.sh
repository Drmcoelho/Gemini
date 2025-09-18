#!/usr/bin/env bash
# install-ubuntu.sh — Setup para Ubuntu/Debian (apt-get)
echo "[INFO] Setup Ubuntu/Debian (apt-get)"

set -u

need(){ command -v "$1" >/dev/null 2>&1; }

# Atualiza índices
sudo apt-get update -y

# Dependências
sudo apt-get install -y jq curl ca-certificates
# yq (opcional) — tenta pacote se disponível, senão via snap/pip
if ! need yq; then
  if sudo apt-get install -y yq; then :; else
    if command -v snap >/dev/null 2>&1; then
      sudo snap install yq || true
    else
      echo "[WARN] yq não instalado (opcional)."
    fi
  fi
fi

# direnv
if ! need direnv; then
  sudo apt-get install -y direnv || echo "[WARN] direnv não instalado automaticamente."
fi

# Node/npm (para fallback do gemini-cli)
if ! need node || ! need npm; then
  sudo apt-get install -y nodejs npm || true
fi

# Gemini CLI
if ! need gemini && ! need gmini; then
  if need npm; then
    sudo npm i -g @google/gemini-cli || {
      echo "[ERR ] Não foi possível instalar @google/gemini-cli. Instale manualmente."
    }
  else
    echo "[WARN] npm não encontrado; instale Node/NPM e rode: npm i -g @google/gemini-cli"
  fi
fi

# direnv hook
shellrc="${HOME}/.bashrc"
if [ -n "${ZSH_VERSION:-}" ]; then shellrc="${HOME}/.zshrc"; fi
hook='eval "$(direnv hook bash)"'
if [ -n "${ZSH_VERSION:-}" ]; then hook='eval "$(direnv hook zsh)"'; fi

if [ -f "$shellrc" ]; then
  grep -Fq "$hook" "$shellrc" || printf '\n# direnv (Gemini Megapack)\n%s\n' "$hook" >> "$shellrc"
else
  printf '%s\n' "$hook" > "$shellrc"
fi

if need direnv; then
  direnv allow . || true
fi

echo "[INFO] Ubuntu/Debian pronto. Faça login:"
echo "  ./gemx.sh login"
