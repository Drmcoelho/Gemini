#!/usr/bin/env bash
# uninstall.sh — Remove artefatos locais do projeto (conservador).
echo "[INFO] Uninstall local do Gemini Megapack (não remove o Gemini CLI global)."

proj_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$proj_dir" || exit 1

# Remover 'direnv allow' não é necessário; apenas informe.
echo "[INFO] Remova manualmente o hook do direnv do seu ~/.zshrc se quiser:"
echo '  # procure por: eval "$(direnv hook zsh)"'
echo
echo "[INFO] Artefatos locais (mantenho por padrão): .env, .envrc, automations/, others.json, gemx.sh."
echo "[INFO] Caso deseje limpar, execute:"
echo "  rm -rf .env .envrc automations/ others.json gemx.sh templates/"
echo
echo "[INFO] Para remover o Gemini CLI instalado via npm:"
echo "  npm uninstall -g @google/gemini-cli"
echo
echo "[INFO] Uninstall concluído (nenhuma ação destrutiva automática executada)."
