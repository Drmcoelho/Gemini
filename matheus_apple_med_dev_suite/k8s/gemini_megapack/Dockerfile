# Dockerfile — Gemini Megapack (Web + CLI)
# multi-stage para imagem final enxuta
FROM python:3.11-slim AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# deps do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    jq curl ripgrep git fzf ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

# usuário não-root
RUN useradd -m -u 10001 app
WORKDIR /app
COPY . /app

# dependências Python (web)
RUN pip install --no-cache-dir -r web/requirements.txt

# permissões de execução
RUN chmod +x /app/gemx.sh /app/*.sh /app/dist/*.sh || true

# porta do web app
EXPOSE 8080

# variável para forçar o modelo e modo web
ENV GEMX_FORCE_MODEL=gemini-2.5-pro \
    GEMX_HOME=/home/app/.config/gemx

# criar diretórios de config/logs/hist
RUN mkdir -p /home/app/.config/gemx/{history,logs} && chown -R app:app /home/app

# entrada via tini (melhor manejo de sinais)
ENTRYPOINT ["/usr/bin/tini","--"]

# comando padrão (uvicorn)
USER app
CMD ["uvicorn","web.app:app","--host","0.0.0.0","--port","8080"]
