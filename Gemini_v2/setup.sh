#!/usr/bin/env bash
# setup.sh — Configura o ambiente para a API Web do Gemini Megapack v2

echo "[INFO] Iniciando a configuração do ambiente para a API Web do Gemini Megapack v2..."

# Navegar para o diretório Gemini_v2
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR" || { echo "[ERR] Não foi possível navegar para o diretório do script."; exit 1; }

echo "[INFO] Instalando dependências Python (FastAPI, Uvicorn, Pydantic)..."
pip install fastapi uvicorn[standard] pydantic || { echo "[ERR] Falha ao instalar dependências Python."; exit 1; }

echo "[INFO] Configuração da API Web concluída."
echo
echo "Para iniciar a API Web, execute o seguinte comando no diretório '$SCRIPT_DIR':"
echo "  uvicorn gemx_web.main:app --host 0.0.0.0 --port 8000"
echo
echo "Após iniciar, a API estará disponível em http://0.0.0.0:8000"
echo "A documentação interativa da API (Swagger UI) estará em http://0.0.0.0:8000/docs"
echo
echo "Certifique-se de que o script gemx.sh (no mesmo diretório) tenha permissões de execução:"
echo "  chmod +x gemx.sh"
echo "E que o Gemini CLI esteja configurado e autenticado."
