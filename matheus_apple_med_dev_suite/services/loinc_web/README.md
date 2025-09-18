# LOINC + Web Deploy (FastAPI + SQLite/FTS5)

**Importador LOINC** + **UI web** de busca + **APIs REST** + **Docker/Compose/Helm** prontos.

> ⚖️ **Licença**: Este pacote **não** inclui dados LOINC. Baixe do site oficial (Regenstrief), aceite os termos e use o importador.
> 💡 **Sem PHI**: A aplicação é uma ferramenta de consulta; use dados não-identificáveis.

## 1) Importar LOINC → SQLite
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r app/requirements.txt

# baixe o CSV (veja scripts/README_LOINC_DOWNLOAD.md)
python scripts/loinc_import.py --csv /caminho/LoincTableCore.csv --db ./data/loinc.sqlite
```

## 2) Rodar local
```bash
cd app
DB_PATH=../data/loinc.sqlite uvicorn app:app --reload --port 8080
# http://localhost:8080
```

## 3) Docker / Compose
```bash
docker build -t loinc-web:latest .
docker compose up -d                # expõe 8088->8080

# com Traefik (labels prontos)
DOMAIN=loinc.example.com docker compose -f docker-compose.traefik.yml up -d
```

## 4) Helm (Kubernetes)
```bash
helm upgrade --install loinc charts/loinc-web \
  --set image.repository=ghcr.io/YOUR_ORG/loinc-web \
  --set ingress.hosts[0].host=loinc.example.com \
  --set ingress.tls[0].hosts[0]=loinc.example.com
# Se quiser Job de ingestão (CSV já montado em /seed):
helm upgrade --install loinc charts/loinc-web \
  --set loader.enabled=true --set loader.csvPath=/seed/LoincTableCore.csv
```

## 5) API
- `GET /api/ping`
- `GET /api/loinc/code/{code}`
- `GET /api/loinc/search?q=<query>&limit=25&offset=0` (FTS5 quando disponível)
- `GET /api/loinc/suggest?prefix=234`

## 6) UI
- Busca via **HTMX** (layout simples, responsivo).

## Segurança
- SQLite em PVC/Volume dedicado; backup periódico.
- Logs mínimos; adicione reverso com autenticação se publicar externamente (Traefik Nginx Ingress + OAuth, etc.).
- Sem PHI; dados LOINC são referenciais (terminologia).

Boa prática: combine com seu **medcli** e base de dicionários locais para enriquecer análises.
