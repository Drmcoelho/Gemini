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
  echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
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
{"ts":"2025-09-18T12:34:56Z","event":"start","wd":"/path/proj","bin":"gemini","model":"gemini-2.5-pro","argv":["generate","--model","gemini-2.5-pro","--prompt","..."]}
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
