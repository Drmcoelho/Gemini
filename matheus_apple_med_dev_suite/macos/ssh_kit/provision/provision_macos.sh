#!/usr/bin/env bash
# Provisioning leve para múltiplos Macs (brew + pacotes + configs + launchagents)
set -euo pipefail

confirm(){ read -rp "$1 [y/N]: " a; [[ "${a,,}" =~ ^y(es)?$ ]]; }

# Homebrew e apps
if ! command -v brew >/dev/null 2>&1; then
  if confirm "Instalar Homebrew?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

pkgs=(openssh libfido2 fzf ripgrep hammerspoon autossh)
casks=(tailscale zerotier-one)
if confirm "Instalar pacotes via brew? (${pkgs[*]})"; then
  brew install "${pkgs[@]}" || true
  brew install --cask "${casks[@]}" || true
fi

# FZF keybindings (opcional)
if confirm "Configurar keybindings do fzf?"; then
  yes | "$(brew --prefix)"/opt/fzf/install || true
fi

# Copiar assets (scripts/bin)
mkdir -p "$HOME/.local/bin"
install -m 0755 bin/sshx "$HOME/.local/bin/sshx"
install -m 0755 bin/ssh-tunnel "$HOME/.local/bin/ssh-tunnel"

# Hammerspoon
if confirm "Instalar Hammerspoon init.lua?"; then
  mkdir -p "$HOME/.hammerspoon"
  cp -f hammerspoon/init.lua "$HOME/.hammerspoon/init.lua"
fi

echo "[OK] Provisionamento básico concluído."
echo "Sugestão: adicione o zsh snippet ao seu ~/.zshrc:"
echo "  cat shell/.zshrc.sshx >> ~/.zshrc"
