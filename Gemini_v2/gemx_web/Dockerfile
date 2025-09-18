# Backend (FastAPI) Dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash curl jq ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# yq binary
ARG YQ_VERSION=v4.44.3
RUN curl -fsSL -o /usr/local/bin/yq \
      https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
 && chmod +x /usr/local/bin/yq

WORKDIR /app

# Copy entire Gemini_v2 build context into /app/Gemini_v2
# Build context is set to Gemini_v2/ in docker-compose
COPY . /app/Gemini_v2/

# Python deps for API
RUN pip install --upgrade pip \
 && pip install fastapi "uvicorn[standard]" pyyaml

# Optional: install google-genai or gemini CLI if available externally
# RUN pip install google-genai

EXPOSE 8000

ENV GEMX_AUTOMATIONS_DIRS="/app/Gemini_v2/automations:/app/automations" \
    GEMX_QUIET=1

# Change working directory to package root for simpler module path
WORKDIR /app/Gemini_v2

# Dev: reload; Prod: override CMD without --reload
CMD ["uvicorn", "gemx_web.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
