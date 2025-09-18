# Gemini Megapack — CLI + Wrapper (Login Google, sem API)


## 0) Instalação 1‑comando (recomendado)

```bash
# dentro da pasta do pacote
chmod +x install.sh && ./install.sh
# ou via Makefile
make install
make doctor
```

Este pacote entrega um wrapper **robusto** para o **Gemini CLI** (login via Google, **sem** API key), automations, catálogo `others.json`, templates e bootstrap de ambiente via `.env`/`.envrc`.

> **Padrão rígido de modelo:** `gemini-2.5-pro`. O wrapper aplica `GEMX_FORCE_MODEL=gemini-2.5-pro`, que **sobrepõe qualquer escolha**.

---

## 1) Instalação rápida

- **Binário oficial** (recomendado):  
  `brew install gemini-cli` (macOS) ou `npm i -g @google/gemini-cli` (Node 20+).

- **Login Google (sem API)**:
  ```bash
  ./gemx.sh login
  ./gemx.sh whoami
  ```

- **Ativar ambiente do projeto** (usando **direnv**):
  ```bash
  brew install direnv
  echo 'eval "$(direnv hook zsh)"'> ~/.zshrc
  cd /sua/pasta/do/projeto && direnv allow .
  ```

---


## 2) Estrutura do pacote

```
gemini_megapack/
├─ gemx.sh               # wrapper principal (sempre gemini-2.5-pro; lê others.json)
├─ .env                  # aliases e variáveis (GEMX_FORCE_MODEL=gemini-2.5-pro)
├─ .envrc                # direnv: carrega .env e aliases ao entrar na pasta
├─ others.json           # catálogo de extensões/plugins/interações/automations
├─ automations/
│  ├─ rx_brief.yaml
│  ├─ sgarbossa_check.yaml
│  └─ batch_from_file.sh
├─ templates/
│  └─ README.md
└─ gemini.md             # esta documentação
```

---


## 3) Filosofia do wrapper

- **Somente binário** (Google login). Sem chamadas HTTP.
- **Compat macOS** (bash 3.2): sem dependências GNU não-portáteis.
- **Modelo forçado**: `GEMX_FORCE_MODEL=gemini-2.5-pro` garante consistência.
- **Pass-through**: qualquer subcomando/flag novo do CLI oficial funciona via:
  ```bash
  ./gemx.sh passthrough -- <args do gemini>
  ```
- **others.json**: catálogo editável pelo usuário: extensões, plugins (toggles), interações e automations.

---


## 4) Comandos do wrapper

```bash
./gemx.sh menu                      # TUI simples
./gemx.sh setup                     # deps/binário
./gemx.sh login|whoami|logout       # conta
./gemx.sh models [set <MODEL>]      # lista/define modelo (pode ser sobreposto por FORCE_MODEL)
./gemx.sh project set <ID>          # GOOGLE_CLOUD_PROJECT
./gemx.sh chat                      # chat interativo
./gemx.sh gen [flags]               # geração one-shot
./gemx.sh vision --image PATH [...] # visão
./gemx.sh tpl ls|show <KEY>         # templates do config.json
./gemx.sh profile apply <NAME>      # aplica perfil do config.json
./gemx.sh auto ls|new|show|run      # automations
./gemx.sh others                    # menu do others.json
./gemx.sh cache ls|clear            # cache (se suportado)
./gemx.sh passthrough -- ...        # repassa args para o binário
```

### Flags comuns (gen/vision)
- `--prompt "..."` | `--prompt-file F` | `--editor`  
- `--model NAME` *(pode ser sobreposto pelo FORCE_MODEL)*  
- `--temp N.N`  
- `--system "mensagem"`  
- `--image PATH` (em `vision` ou em `gen` como adicional)  
- `--` *(tudo após vai direto ao binário, ex.: `--max-output-tokens 2048`)*

---


## 5) others.json — catálogo

Exemplo (incluído no pacote):
```json
{
  "extensions": [
    {"id": "dlvhdr/gh-dash", "description": "Dashboard TUI GitHub"},
    {"id": "github/gh-copilot", "description": "Copilot via gh"}
  ],
  "plugins": [
    {"key": "web_fetch", "default": false, "description": "Contexto web (se suportado)"},
    {"key": "image_caption", "default": false, "description": "Caption de imagem"}
  ],
  "interactions": [
    {"id": "template_rx", "type": "template", "label": "RX", "template_key": "rx"},
    {"id": "prompt_brief", "type": "prompt", "label": "Brief", "prompt": "Resuma em 5 bullets."},
    {"id": "auto_rx_brief", "type": "automation", "label": "Automation RX", "file": "automations/rx_brief.yaml"}
  ],
  "automations": [
    {"file": "automations/rx_brief.yaml", "description": "Condutas RX"},
    {"file": "automations/sgarbossa_check.yaml", "description": "Critérios Sgarbossa"},
    {"file": "automations/batch_from_file.sh", "description": "Lote por arquivo"}
  ]
}
```

> Edite e acrescente seus itens. O menu `others` instala extensões (via `gh`), faz **toggle** dos plugins (gravando em `config.json`), executa interações (template/prompt/automation) e roda automations registradas.

---


## 6) Automations

- **YAML/JSON**: precisam de `yq`/`jq` para parse (o wrapper usa o que existir).
- **Scripts executáveis**: qualquer `.sh` com `chmod +x` pode ser rodado via `auto run`.
- Convenção simples:
  - `name`, `model` (será **forçado** para `gemini-2.5-pro` se `GEMX_FORCE_MODEL` estiver setado),
  - `temperature`, `prompt`, `extra_args`.

---


## 7) Fluxos práticos

**A)** Abordagem rápida com aliases (ao entrar na pasta com direnv):
```bash
gx           # menu
gxg --prompt "Explique IRA pré-renal vs ATN em 5 bullets."
gxv --image rx.png --prompt "Descreva o achado principal."
gxa run automations/rx_brief.yaml <<<'Pneumonia grave, choque séptico, norepinefrina.'
```

**B)** Pass-through completo para novas flags do CLI oficial:
```bash
./gemx.sh passthrough -- generate --model gemini-2.5-pro --temperature 0.3 --prompt "teste" --max-output-tokens 1024
```

**C)** Forçar ambiente sempre pronto:
- `.env` define `GEMX_FORCE_MODEL="gemini-2.5-pro"` e aliases.
- `.envrc` aplica ao entrar na pasta.

---


## 8) Troubleshooting

- **"gemini: command not found"** → instale o CLI (`brew install gemini-cli`) ou exporte `GEMINI_BIN=/caminho/do/bin`.
- **Loop/erro de login** → `rm -rf ~/.gemini && ./gemx.sh login`.
- **YAML parsing** → instale `yq` (`brew install yq`) para usar automations `.yaml`.
- **Modelo trocado "sozinho"** → o wrapper está **forçando** `gemini-2.5-pro` (veja `GEMX_FORCE_MODEL`).

---


## 9) Roadmap sugerido

- Export JSON canônico; histórico em `.jsonl`.
- Integração `fzf` para busca de histórico e automations.
- Modo "dry-run": imprime o comando final antes de executar.
- Coletores de contexto locais (PDF/MD/CSV) quando o CLI suportar ingestão.

---

**Pronto.** O pacote entrega uma base sólida, prontíssima para expansão e uso diário.


---
## Instalação específica macOS (Homebrew-only)

```bash
chmod +x install-macos.sh && ./install-macos.sh
```

---
## Novas automations incluídas

- `automations/sepse_bundle.yaml` — Bundle T0–6h, antibiótico, volume, vasopressor, farmacologia completa (9 campos).
- `automations/hda_triage.yaml` — Triagem e estabilização da HDA; IBP, vasoativos varicosa, antibiótico; critérios de EDA/transferência.
- `automations/ira_algoritmo.yaml` — Diferenciação Prerrenal vs ATN vs Pós-renal, condutas e ajustes de fármacos.
- `automations/ventilacao_mecanica_inicial.yaml` — Parâmetros iniciais, SDRA, DPOC/asma, sedoanalgesia, metas e alarmes.


---

## 10) Instalação específica macOS

```bash
chmod +x install-macos.sh && ./install-macos.sh
./gemx.sh login
make doctor
```

## 11) Automations médicas (novas)

- `automations/sepse_bundle.yaml`
- `automations/hda_triage.yaml`
- `automations/ira_aki.yaml`
- `automations/ventilacao_mecanica.yaml`
- `automations/broncoespasmo_seco.yaml`

Rode pelo menu **others** (interactions) ou diretamente:
```bash
./gemx.sh auto run automations/sepse_bundle.yaml
```


## 12) Instalação específica Ubuntu/Debian

```bash
chmod +x install-ubuntu.sh && ./install-ubuntu.sh
./gemx.sh login
make doctor
```

## 13) Modo DRY-RUN (auditoria dos comandos)

- Global: `--dry-run` em qualquer comando do wrapper OU `export GEMX_DRYRUN=1` no ambiente.
- Exemplo:
```bash
./gemx.sh --dry-run gen --prompt "teste" -- --max-output-tokens 512
# Saída: [DRY-RUN] gemini generate --model gemini-2.5-pro ...
```


## 14) FZF Center (busca rápida)

Se você tiver `fzf` instalado, habilite navegação turbo:
```bash
./gemx.sh fzf hist      # examina histórico com preview
./gemx.sh fzf auto      # roda automations via picker
./gemx.sh fzf others    # instala extensões, alterna plugins, dispara interações
./gemx.sh fzf tpl       # escolhe template e executa
./gemx.sh fzf models    # escolhe o modelo (será sobreposto por FORCE_MODEL)
```
No menu `gemx.sh menu` há a opção **"FZF Center"** reunindo tudo.

> Dica: muitos itens do `others.json` foram ampliados (extensões/plugins/interações/integrations). Edite-o à vontade.



## 15) Audit JSONL (opcional)

Ative com `others.json → plugins → audit_log_jsonl` (toggle no menu **others**) — o wrapper gravará
eventos `start|finish|dry-run|cancel` em `~/.config/gemx/logs/audit-YYYYMMDD.jsonl`:

Exemplo de linha:
```json
{"ts":"2025-09-18T12:34:56Z","event":"start","wd":"/path/proj","bin":"gemini","model":"gemini-2.5-pro","argv":["generate","--model","gemini-2.5-pro","--prompt","..." ]}
```

Compatível com `--dry-run` e com o toggle `confirm_before_run` (que registra `cancel` se você negar).


## 16) Stats e Navegação de Logs

- **Estatísticas agregadas**:
```bash
./gemx-stats.sh --since 2025-09-01 --top 15
# ou JSON (mínimo): ./gemx-stats.sh --json
```

- **Navegador de Logs (FZF)**:
```bash
./gemx-logs.sh
# Seleciona por ts/event/cmd; preview mostra a linha JSON com jq/bat.
```


## 17) Export CSV

```bash
# Exporta tabelas para ./outcsv/
./gemx-stats.sh --since 2025-09-01 --csv-dir ./outcsv
# Gera: events.csv, top_commands.csv, models.csv, durations.csv, daily.csv
```

## 18) "Grafana-lite" (HTML estático)

Requer Python 3 + matplotlib:
```bash
python3 -m pip install matplotlib
# gerar relatório:
python3 ./gemx-stats-html.py --since 2025-09-01 --out-dir ./gemx_report
# Abra o HTML (macOS):
open ./gemx_report/index.html
# Linux:
xdg-open ./gemx_report/index.html
```

O relatório inclui:
- gráficos (PNG) de eventos, top comandos, modelos, duração média e série diária;
- tabelas com os mesmos dados.


## 19) HTML em lote (batch)

Gere múltiplos relatórios HTML de uma vez:

```bash
# múltiplos intervalos específicos:
python3 ./gemx-stats-html.py --batch "2025-08-01:2025-08-31;2025-09-01:2025-09-30" --out-dir ./reports

# um por mês encontrado nos logs:
python3 ./gemx-stats-html.py --batch-monthly --out-dir ./reports
```

Saída:
```
./reports/
  range_2025-08-01_2025-08-31/index.html
  range_2025-09-01_2025-09-30/index.html
  # ou:
  month_2025-08/index.html
  month_2025-09/index.html
```

## 20) Export Markdown

```bash
# para stdout:
python3 ./gemx-stats-md.py --since 2025-09-01

# salvar em arquivo:
python3 ./gemx-stats-md.py --since 2025-09-01 --out ./stats_2025-09.md

# alias:
gzmd --since 2025-09-01 --out ./stats_2025-09.md
```


---


## 21) Plugins (arquitetura simples)

- `plugins.d/` contém executáveis `.sh` chamados via `./gemx.sh plugins run <nome>`.
- Incluídos:
  - `rag` — contexto via ripgrep (busca local); combine com `./gemx.sh rag gen <kb> "<query>"`.
  - `obsidian_export` — exporta conteúdo para o vault (`others.json → integrations.obsidian_vault` ou `OBSIDIAN_VAULT`).
  - `json_validate` — valida JSON por chaves obrigatórias via `jq`.

Listar:
```bash
./gemx.sh plugins list
./gemx.sh plugins run rag ./kb "sepse noradrenalina"
```

## 22) Perfis

```bash
./gemx.sh profile list
./gemx.sh profile set clinical.json
./gemx.sh profile show research.json
```

## 23) Flows (pipelines multi-etapas)

```bash
./gemx.sh flow flows/flow_example.yml
```

Requer `yq` para YAML completo; sem `yq` cai em fallback (limitado).

## 24) Fila (queue)

```bash
./gemx.sh queue add './gemx.sh gen --prompt "ok"'
./gemx.sh queue run
```

## 25) TUI

```bash
gtui
```

## 26) Completions

- `completions/gemx.zsh` e `completions/gemx.fish`.

## 27) Regras (pré-prompt)

- `rules.d/default.rules.yaml` — bloqueia padrões perigosos quando `safe_prompts=true` em `config.json/others.json`.
- Extensível: adicione `rules.d/*.yaml`.



## 28) Execução distribuída (SSH/parallel)

Arquivos:
- `dist/hosts` — lista de hosts (um por linha; aceita `user@host:porta`).
- `dist/cluster.sh` — executa comando nos hosts (usa `parallel`/`pssh` se houver, senão loop SSH).
- `dist/deploy.sh` — empacota o projeto e publica no host destino (tar+scp).
- `dist/flow.sh` — roda um *flow* em todos os hosts após `deploy`.

CLI:
```bash
./gemx.sh dist hosts
./gemx.sh dist cluster 'uname -a'
./gemx.sh dist deploy ~/gemx
./gemx.sh dist flow ~/gemx flows/flow_example.yml
```

## 29) Assinatura & Atestation de Jobs

- `./queue.sh` agora **assina** cada `.job` (SHA256 em `.attest/attest-YYYYMMDD.jsonl`).
- `./queue-runner.sh` **verifica** a assinatura antes de executar (caso falhe, descarta).
- Ferramentas diretas:
```bash
./sign-job.sh .queue/123.job
./verify-job.sh .queue/123.job
```

## 30) Integrações: Notion & OmniFocus (plugins)

- **Notion** (`plugins.d/notion_export.sh`)
  - Env: `NOTION_TOKEN` e `NOTION_DATABASE_ID` (ou preencha em `others.json → integrations` e exporte).
  - Uso: `./plugins.d/notion_export.sh "Título" "Conteúdo"

- **OmniFocus** (`plugins.d/omnifocus_task.sh`, macOS)
  - Requer `osascript`.
  - Uso: `./plugins.d/omnifocus_task.sh "Título" "Nota" "Projeto" "Tag1,Tag2" "2025-10-01 09:00" "2025-10-02 18:00"

## 31) Subcomando: dist

```bash
./gemx.sh dist {hosts|cluster|deploy|flow}
```



## 32) Batch de Flows (retries + backoff + jitter + paralelo)

```bash
./flow-batch.sh --concurrency 4 --retries 3 --base 2 --max 60 --jitter 5 flows/*.yml
# ou com manifesto:
./flow-batch.sh --manifest flows.txt --concurrency 2
```
- Gera JSONL em `~/.config/gemx/logs/flowbatch-YYYYMMDD.jsonl`.
- Com GNU parallel, roda N flows simultaneamente.
- Estratégia: backoff exponencial com teto `--max` + jitter uniforme `[0..JITTER]`.

Execução distribuída do batch:
```bash
./gemx.sh dist flow-batch ~/gemx --concurrency 4 --retries 2 --manifest flows.txt
```

## 33) Notion avançado (Status / Tags / Anexos)

```bash
# Status e Tags (multi_select), e anexos por URLs (image/file blocks)
./plugins.d/notion_export.sh "Título" "Texto" "Doing" "ML,NLP" "https://site/img1.png https://site/doc.pdf"
# props personalizáveis:
export NOTION_STATUS_PROP="Status"
export NOTION_TAGS_PROP="Tags"
```



## 34) Janelas de Execução (Scheduler leve) — flow-batch

Respeite horários/dias permitidos:
```bash
# dias úteis 08–12 e 14–18
./flow-batch.sh --allow-days "Mon,Tue,Wed,Thu,Fri" --allow-hours "08:00-12:00,14:00-18:00" --concurrency 4 flows/*.yml
```
O batch aguardará fora da janela e **só inicia** execuções quando dentro da janela (cada flow respeita a janela antes de começar).

## 35) FlowBatch Aggregator (CSV + HTML)

```bash
# agrega todos flowbatch-*.jsonl do diretório padrão
python3 ./gemx-flowbatch-agg.py --out-dir ./flowbatch_report

# ou a partir de um padrão específico
python3 ./gemx-flowbatch-agg.py --glob "flowbatch-2025*.jsonl" --out-dir ./flowbatch_Q3_report
```
Saídas:
- `events.csv`, `flows.csv`, `daily.csv`
- `index.html` com gráficos (matplotlib puro) e tabelas.


## 36) Docker & Deploy Web

### Local (Docker)
```bash
# build & run
docker build -t gemini-megapack:latest .
docker run --rm -it -p 8080:8080 \
  -e WEB_USER=admin -e WEB_PASS=change \
  -v gemx_config:/home/app/.config/gemx \
  gemini-megapack:latest

# compose (com Caddy opcional para TLS)
docker compose up -d --build
```
Acesse: `http://localhost:8080/` (UI mínima) e `http://localhost:8080/metrics` (Prometheus).

> Importante: o binário proprietário **gemini/gmini não está incluído**. Se quiser usá-lo dentro do contêiner,
> monte-o em `/usr/local/bin/gemini` ou configure `GEMINI_BIN` e mapeie o caminho correspondente.

### Kubernetes
```bash
# edite a imagem em k8s/deploy.yaml (ghcr.io/your-org/gemini-megapack:latest)
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deploy.yaml
```
Acesse via `Ingress` (configure domínio e issuer do cert-manager).

### Variáveis úteis
- `WEB_USER`, `WEB_PASS` — Basic Auth do painel web.
- `GEMX_FORCE_MODEL=gemini-2.5-pro` — reforça o modelo.
- `NOTION_TOKEN`, `NOTION_DATABASE_ID` — para plugin Notion.
- `OBSIDIAN_VAULT` — caminho montado para export.

### Volumes
- `~/.config/gemx` (logs, history, configs) → **persistir**.

### Makefile
```bash
make build
make up
make k8s-apply
```


## 37) Autenticação OAuth (Google)
Configure as variáveis e rode com Traefik/Caddy ou direto:
```bash
export GOOGLE_CLIENT_ID=...
export GOOGLE_CLIENT_SECRET=...
export OAUTH_CALLBACK_URL="https://seu.dominio/auth/callback"
export ALLOWED_DOMAIN="suaempresa.com"   # ou ALLOWED_EMAILS="a@b.com,c@d.com"
docker compose up -d --build
```
Endpoints: `/auth/login`, `/auth/callback`, `/logout`. Quando OAuth está ativo, os endpoints protegidos exigem sessão.

## 38) Traefik (reverse proxy, TLS, middlewares)
```bash
DOMAIN=gemx.example.com EMAIL=admin@example.com docker compose -f docker-compose.traefik.yml up -d --build
```
Middlewares padrões: compressão e rate-limit. Ajuste `traefik/dynamic.yml`.

## 39) Helm Chart
```bash
helm upgrade --install gm charts/gemx       --set image.repository=ghcr.io/YOUR_ORG/gemini-megapack       --set oauth.enabled=true       --set oauth.googleClientId=$GOOGLE_CLIENT_ID       --set oauth.googleClientSecret=$GOOGLE_CLIENT_SECRET       --set oauth.callbackUrl="https://gemx.example.com/auth/callback"       --set ingress.hosts[0].host=gemx.example.com
```
Veja `charts/gemx/values.yaml` para sidecars (Vector/Fluent Bit), Auth básico, PVC etc.

## 40) CI/CD (GitHub Actions, SBOM, assinatura)
Workflow: `.github/workflows/docker.yml` — buildx multi-arch (amd64/arm64), push para GHCR, SBOM (Syft) e assinatura **keyless** (cosign).

## 41) Sidecars de Logs
Exemplos prontos em `k8s/vector-sidecar.yaml` e `k8s/fluentbit-sidecar.yaml`. Monte `/home/app/.config/gemx/logs` no sidecar para coletar `audit-*.jsonl` e `flowbatch-*.jsonl`.

## 42) Helm — GKE Autopilot (values-gke.yaml)
```bash
helm dependency update charts/gemx
helm upgrade --install gm charts/gemx -f charts/gemx/values-gke.yaml       --set ingress.hosts[0].host=gemx.seu-dominio.com       --set ingress.tls[0].hosts[0]=gemx.seu-dominio.com
```
- Service anotado com **NEG** (container-native LB).
- `ingress.className: gce` com TLS (pode integrar com ManagedCertificate se desejar).

## 43) Traefik como dependência do Chart
- `charts/gemx/Chart.yaml` inclui **Traefik** (condicional `traefik.enabled`).
- `values-traefik.yaml` habilita Traefik com ACME (TLS), redirect HTTP→HTTPS.

## 44) Terraform — GKE Autopilot + Helm + DNS
Caminho: `infra/terraform/gke/`  
Provisiona:
- GKE Autopilot
- cert-manager (Helm)
- Traefik (opcional, Helm)
- gemx (Helm, chart local)
- (Opcional) Managed Zone DNS

Uso:
```bash
cd infra/terraform/gke
cp terraform.tfvars.example terraform.tfvars   # edite
terraform init && terraform apply -auto-approve
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get ingress
```

## 45) GKE ManagedCertificate (opcional)
Ative em `values.yaml`:
```yaml
ingress:
  managedCertificate:
    enabled: true
```
O template `templates/managedcert.yaml` criará o recurso para os hosts configurados.

```

---

## 4. Próximos Passos: Integração da Base de Conhecimento

A recente adição de uma biblioteca de referência médica (manuais de emergência em PDF e o arquivo `drogas.md`) abre novas e importantes frentes de desenvolvimento para a suite. Os próximos passos se concentrarão em integrar este conhecimento diretamente nas ferramentas existentes:

### 4.1. Alimentar o Plugin de RAG (Retrieval-Augmented Generation)
- **Ação:** Indexar o conteúdo textual dos novos PDFs e do arquivo `drogas.md`.
- **Objetivo:** Permitir que o `gemx.sh rag` possa realizar buscas e extrair informações diretamente desta base de conhecimento. Isso transformará o RAG de um buscador de contexto genérico para uma ferramenta de consulta de referência médica, capaz de responder perguntas como "qual a dose de ataque de amiodarona na FV?" com base nos manuais.

### 4.2. Validar e Refinar as Automações Clínicas
- **Ação:** Realizar uma revisão cruzada dos protocolos de automação existentes (`sca_protocol.yaml`, `avc_protocol.yaml`, etc.) contra as diretrizes e tabelas presentes nos PDFs.
- **Objetivo:** Aumentar a robustez e a precisão dos prompts, garantindo que as perguntas interativas e as seções de tratamento estejam alinhadas com as melhores práticas descritas na literatura adicionada. Isso inclui refinar doses, contraindicações e fluxos de decisão.

### 4.3. Expansão do Conteúdo Didático
- **Ação:** Usar as tabelas de medicamentos e os algoritmos dos PDFs como base para criar novos notebooks didáticos.
- **Objetivo:** Desenvolver notebooks focados em:
    - **`04_Calculo_de_Drogas_de_Emergencia.ipynb`**: Um guia interativo para calcular doses de drogas vasoativas e outras medicações de emergência.
    - **`05_Interpretacao_de_Algoritmos_ACLS.ipynb`**: Um notebook que disseca os algoritmos de parada cardiorrespiratória presentes nos manuais.

```