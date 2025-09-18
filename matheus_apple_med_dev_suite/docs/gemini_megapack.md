# Documentação: `k8s/gemini_megapack`

O **Gemini Megapack** é o coração da suite, um sistema sofisticado para interagir com os modelos de linguagem da Google (Gemini) de maneira estruturada, automatizada e pronta para produção.

## Arquitetura e Conceitos

O megapack é construído em torno de um wrapper central, o `gemx.sh`, e é projetado para ser executado tanto localmente (via Docker) quanto em escala na nuvem (via Kubernetes).

### 1. `gemx.sh` - O Wrapper Central

Este não é um simples script, mas um centro de comando completo para interagir com o Gemini.

- **Gerenciamento de Configuração**: Usa um arquivo `~/.config/gemx/config.json` para gerenciar o modelo padrão, temperatura, system prompts e plugins.
- **Perfis (`profiles/`)**: Permite a troca rápida entre diferentes contextos de trabalho (ex: `clinical`, `coding`, `research`) que alteram o comportamento do modelo.
- **Templates**: Permite salvar e reutilizar prompts complexos.
- **Automations (`automations/`)**: O recurso mais poderoso. Permite a execução de protocolos clínicos pré-definidos em arquivos YAML, que geram saídas estruturadas e detalhadas.
- **Interface Interativa**: Possui um menu principal (`gemx.sh menu`) e menus baseados em `fzf` para uma navegação fluida pelo histórico, automações e outras funcionalidades.
- **Logging e Auditoria**: Pode ser configurado para registrar todas as interações em arquivos `audit-*.jsonl`, permitindo análises de uso e custos.

### 2. Automations Clínicas

Localizadas em `automations/`, estas são o principal caso de uso do megapack no domínio médico. São arquivos YAML que definem um `prompt` detalhado e estruturado para o Gemini.

- **Exemplos**: `sepse_bundle.yaml`, `hda_triage.yaml`, `ira_aki.yaml`.
- **Estrutura**: Cada automação pede ao modelo para gerar uma saída seguindo um formato rigoroso, incluindo seções como avaliação, farmacoterapia (com apresentação, diluição, posologia), critérios de decisão e checklists.
- **Execução**: `gemx.sh auto run automations/sepse_bundle.yaml`

### 3. Flow Engine

Os scripts `flow-run.sh` e `flow-batch.sh` representam um motor de workflow simples.

- `flows/flow_example.yml`: Define um pipeline de múltiplas etapas que pode, por exemplo, primeiro usar RAG (Retrieval-Augmented Generation) para buscar contexto em uma base de conhecimento local e, em seguida, passar esse contexto para um prompt de geração.
- `flow-batch.sh`: Executa múltiplos flows em lote, com controle de concorrência, retries e backoff exponencial.

### 4. Web API e UI

Localizada em `web/`, a aplicação FastAPI fornece uma interface HTTP para o `gemx.sh`.

- **API**: Expõe endpoints como `/api/gen` e `/api/flow` que executam o `gemx.sh` no backend.
- **UI**: Uma página estática (`static/index.html`) oferece uma interface simples para testar os endpoints da API.
- **Autenticação**: Suporta autenticação via Basic Auth ou, em um cenário de produção, **OAuth2** com Google, permitindo o login seguro de usuários e o controle de acesso por domínio ou lista de e-mails.

## Deployment

O megapack é projetado para ser implantado em múltiplos ambientes.

### a) Docker Compose

- `docker-compose.yml`: Configuração padrão para subir o serviço `gemx` e um proxy reverso opcional com **Caddy**.
- `docker-compose.traefik.yml`: Uma configuração alternativa para usar **Traefik** como reverse proxy, que se integra bem com o Docker.
- **Volumes**: O `gemx_config` é montado como um volume para garantir a persistência das configurações e do histórico.

### b) Kubernetes (Helm + Terraform)

Esta é a forma mais robusta de implantar o megapack em produção.

- **Terraform (`infra/terraform/gke/`)**: Os scripts do Terraform provisionam toda a infraestrutura necessária em um projeto Google Cloud:
    - Um cluster **GKE Autopilot**, que é gerenciado e escalável.
    - Opcionalmente, uma zona de DNS gerenciada.
    - Gera um `kubeconfig` para acesso ao cluster.

- **Helm (`charts/gemx/`)**: O Helm chart gerencia a implantação da aplicação no cluster Kubernetes.
    - **Recursos**: Cria `Deployment`, `Service`, `PersistentVolumeClaim`, `Secret` e `Ingress`.
    - **Ingress & Certificados**: Suporta múltiplos Ingress controllers (`gce`, `traefik`, `nginx`) e se integra com `cert-manager` (ou o `ManagedCertificate` do GKE) para provisionar certificados TLS automaticamente.
    - **Autenticação**: Os segredos do OAuth2 (Client ID, Secret) são gerenciados através de `Secrets` do Kubernetes e passados para a aplicação como variáveis de ambiente.
    - **Configurabilidade**: Quase todos os aspectos da implantação são configuráveis através dos arquivos `values.yaml`, `values-gke.yaml`, e `values-traefik.yaml`.

## Análise e Monitoramento

- **Logs**: O `gemx.sh` pode gerar logs de auditoria detalhados em formato JSONL.
- **`gemx-logs.sh`**: Um script que usa `fzf` para navegar e pesquisar interativamente nos logs de auditoria.
- **`gemx-stats.sh`**: Gera estatísticas de uso a partir dos logs (comandos mais usados, modelos, etc.).
- **`gemx-stats-html.py` / `gemx-stats-md.py`**: Scripts Python que geram relatórios de uso mais elaborados em HTML (com gráficos) ou Markdown.
- **Métricas Prometheus**: A API web expõe um endpoint `/metrics` com métricas no formato Prometheus, que pode ser usado para monitorar a saúde e o uso da aplicação.
