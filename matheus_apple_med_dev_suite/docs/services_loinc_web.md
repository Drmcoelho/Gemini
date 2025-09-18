# Documentação: `services/loinc_web`

O `loinc_web` é um microserviço autocontido que fornece uma interface web e uma API REST para pesquisar a terminologia médica LOINC.

## Arquitetura

- **Backend**: **FastAPI**, um framework web Python moderno e de alta performance.
- **Banco de Dados**: **SQLite**, um banco de dados leve e baseado em arquivo. O schema inclui suporte para a extensão **FTS5** (Full-Text Search), permitindo buscas textuais extremamente rápidas.
- **Frontend**: Uma interface de usuário simples e reativa, construída com HTML padrão e **HTMX**, que permite atualizações dinâmicas da página sem a necessidade de JavaScript complexo.
- **Containerização**: O serviço é totalmente containerizado usando **Docker**.

## Funcionalidades

### 1. Importador de Dados

- **Script**: `scripts/loinc_import.py`
- **Função**: Lê o arquivo CSV oficial do LOINC (`LoincTableCore.csv`) e o importa para o banco de dados SQLite, populando a tabela principal e o índice FTS5.
- **Uso**: `make loinc-import CSV=/path/to/LoincTableCore.csv`

> **Nota de Licença**: Este serviço não distribui os dados LOINC. Você deve baixá-los do [site oficial da Regenstrief](https://loinc.org/downloads/loinc/) e aceitar seus termos de licença antes de usar o importador.

### 2. API REST

O serviço expõe os seguintes endpoints:

- `GET /api/ping`
  - Um health check simples. Retorna `{"ok": true}`.
- `GET /api/loinc/code/{code}`
  - Retorna os detalhes completos de um único código LOINC.
- `GET /api/loinc/search?q=<query>`
  - Realiza uma busca full-text (usando FTS5) ou com `LIKE` (fallback) no banco de dados. Suporta paginação com os parâmetros `limit` e `offset`.
- `GET /api/loinc/suggest?prefix=<prefix>`
  - Fornece sugestões de autocompletar para códigos e nomes LOINC.

### 3. Interface Web

- **URL**: `/`
- **Funcionalidade**: Uma página de busca simples que permite ao usuário digitar um termo e ver os resultados em uma tabela. A busca é feita de forma assíncrona usando HTMX, que chama o endpoint `/ui/search` e renderiza o HTML de resposta na tabela de resultados.

## Deployment

O `loinc_web` é projetado para ser flexível no deployment.

### a) Localmente (Uvicorn)

Para desenvolvimento, você pode rodar o servidor diretamente:
```bash
make loinc-run
```
Isso sobe o serviço em `http://localhost:8080` com hot-reload.

### b) Docker Compose

Para um ambiente de produção ou teste mais robusto, use o Docker Compose:

```bash
# Constrói a imagem e sobe o contêiner
make loinc-docker
```
O serviço estará disponível em `http://localhost:8088`. O `docker-compose.yml` também inclui um `healthcheck`.

Opcionalmente, `docker-compose.traefik.yml` pode ser usado para integrar com um reverse proxy Traefik.

### c) Kubernetes (Helm)

Para deployment em produção em um cluster Kubernetes, um **Helm Chart** completo está disponível em `charts/loinc-web`.

- **Instalação**: `make helm-loinc-install`
- **Funcionalidades do Chart**:
    - Cria um `Deployment` e um `Service`.
    - Cria um `PersistentVolumeClaim` (PVC) para armazenar o banco de dados SQLite de forma persistente.
    - Opcionalmente, cria um `Ingress` para expor o serviço externamente.
    - Opcionalmente, pode executar um `Job` de importação para popular o banco de dados no primeiro deploy, caso o CSV do LOINC seja disponibilizado em um volume.
