# Docker — Gemini_v2

Este guia ajuda a subir o backend (FastAPI) e o frontend (CRA) via Docker Compose para desenvolvimento.

## Pré-requisitos

- Docker 24+
- Docker Compose v2 (integrado ao Docker Desktop/CLI)

## Subir ambiente de desenvolvimento

Na pasta `Gemini_v2/` execute:

```
docker compose up --build
```

Serviços:
- Backend: http://localhost:8000 (OpenAPI em `/docs`)
- Frontend: http://localhost:3003

Observações:
- Hot-reload habilitado no backend (uvicorn `--reload`) e frontend (`npm start`).
- Volumes montados: código do `Gemini_v2` e `../automations` como leitura.
- Múltiplas raízes de automations via `GEMX_AUTOMATIONS_DIRS`.

## Produção (resumo)

- Usar imagem do backend sem `--reload`.
- Fazer build do frontend (`npm run build`) e servir estático (Nginx/Caddy).
- Configurar CORS restrito e variáveis de ambiente sensíveis.
