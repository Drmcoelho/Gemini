# Gemini Megapack v2: A Plataforma Definitiva para Inteligência Clínica

## Visão Geral e Propósito Fundamental

O **Gemini Megapack v2** transcende a definição de um simples conjunto de ferramentas; ele representa uma **plataforma de inteligência clínica especializada**, meticulosamente projetada para capacitar profissionais de saúde em ambientes de alta demanda, como unidades de emergência (UPA) e terapia intensiva (UTI). Construído sobre o poderoso CLI `gemx` (Gemini Command Line Interface), este Megapack integra o que há de mais avançado em inteligência artificial generativa para oferecer suporte decisivo, otimização de fluxos de trabalho e acesso instantâneo a informações médicas estruturadas.

Nossa visão é transformar a maneira como a informação clínica é acessada, processada e aplicada, permitindo que médicos, enfermeiros e outros profissionais dediquem mais tempo ao cuidado direto do paciente e menos à burocracia ou à busca exaustiva por dados. O Gemini Megapack v2 é um passo audacioso em direção a uma medicina mais eficiente, precisa e humanizada.

## Arquitetura e Filosofia de Design

O Megapack v2 adota uma arquitetura modular e extensível, garantindo flexibilidade e adaptabilidade. Ele se baseia no princípio de que a inteligência artificial deve ser uma ferramenta de **aumento da capacidade humana**, não um substituto.

*   **Core `gemx` CLI**: No coração do Megapack está o `gemx` (implementado em Python), que serve como o motor de comunicação com os modelos Gemini. O Megapack v2 empacota e configura este core para um desempenho otimizado no contexto clínico.
*   **Modularidade por Domínio**: A estrutura de diretórios `v2`, `v3`, etc., permite a criação de "packs" especializados para diferentes domínios (médico, jurídico, engenharia, etc.), cada um com suas próprias automações, configurações e documentação, sem interferir nos demais.
*   **Automação Inteligente**: Utiliza arquivos `.yaml` para definir automações complexas, que são essencialmente "receitas" para o `gemx` executar tarefas específicas, como gerar protocolos ou analisar cenários clínicos.
*   **Observabilidade Integrada**: Ferramentas robustas de logging e reporting garantem transparência e a capacidade de analisar o uso e o desempenho do sistema ao longo do tempo.
*   **Independência de Plataforma**: Embora otimizado para macOS e Ubuntu/Debian, o design busca a máxima compatibilidade, utilizando ferramentas de linha de comando amplamente disponíveis.

## Componentes Principais e Funcionalidades Detalhadas

### 1. Scripts de Instalação e Gerenciamento

O Megapack v2 oferece uma experiência de configuração sem atritos, garantindo que o ambiente esteja pronto para uso com o mínimo de esforço.

*   **`install.sh` (Instalador Universal)**: Este script inteligente detecta o sistema operacional (macOS, Ubuntu/Debian, etc.) e o gerenciador de pacotes (`brew`, `apt`, `dnf`, `pacman`) para instalar automaticamente as dependências essenciais:
    *   `jq`: Processamento de JSON em linha de comando.
    *   `yq`: Processamento de YAML em linha de comando (essencial para as automações).
    *   `direnv`: Gerenciamento de ambiente por diretório.
    *   `gemini-cli`: O CLI oficial do Google Gemini, que o `gemx` encapsula.
    *   **Uso**: `./install.sh`
*   **`install-macos.sh` (Otimizado para macOS)**: Script focado em Homebrew para usuários de macOS, garantindo uma instalação suave e integração com o ecossistema Apple.
    *   **Uso**: `./install-macos.sh`
*   **`install-ubuntu.sh` (Otimizado para Ubuntu/Debian)**: Script para sistemas baseados em Debian/Ubuntu, utilizando `apt-get` e `snap` (se disponível) para gerenciar as dependências.
    *   **Uso**: `./install-ubuntu.sh`
*   **`Makefile`**: Um arquivo `Makefile` centralizado que simplifica a execução de tarefas comuns:
    *   `make install`: Executa o script de instalação apropriado.
    *   `make doctor`: Roda o diagnóstico do ambiente.
    *   `make uninstall`: Inicia o processo de desinstalação.
    *   `make clean`: Limpa arquivos temporários e caches.
    *   **Uso**: `make <comando>`
*   **`uninstall.sh` (Desinstalador Conservador)**: Remove os artefatos locais do Megapack, mas de forma conservadora, fornecendo instruções claras para a remoção manual de hooks do `direnv` ou do `gemini-cli` global, garantindo que nenhuma alteração indesejada persista.
    *   **Uso**: `./uninstall.sh`

### 2. Ferramentas de Diagnóstico

*   **`doctor.sh` (O Clínico Geral do Ambiente)**: Este script é sua primeira linha de defesa para garantir que o ambiente Gemini Megapack esteja saudável. Ele realiza uma série de verificações:
    *   **Verificação de Ferramentas Essenciais**: Confirma a presença e a versão de `gemini`, `gmini`, `jq`, `yq`, `direnv`, `npm`, `node`.
    *   **Status do `direnv`**: Verifica se o `direnv` está ativo para o diretório atual, crucial para o carregamento correto das variáveis de ambiente.
    *   **Variáveis de Ambiente Críticas**: Checa a configuração de variáveis como `GEMX_FORCE_MODEL`.
    *   **Teste de Conectividade Gemini**: Tenta executar `gemini whoami` para verificar a autenticação e a conectividade com a API do Gemini.
    *   **Como Interpretar**: Fornece feedback claro (OK, MISS, WARN) para cada verificação, ajudando a identificar e resolver problemas rapidamente.
    *   **Uso**: `./doctor.sh`

### 3. Sistema de Automações Clínicas (O Coração do Megapack)

O diretório `automations/` é onde a inteligência clínica do Megapack v2 realmente brilha. Cada arquivo `.yaml` representa uma automação específica, projetada para interagir com o modelo Gemini e gerar respostas estruturadas para cenários médicos.

*   **Estrutura de uma Automação (`.yaml`)**:
    *   `name`: Nome único da automação.
    *   `model`: Modelo Gemini a ser utilizado (ex: `gemini-2.5-pro`).
    *   `temperature`: Criatividade do modelo (0.0 a 1.0).
    *   `prompt`: A instrução principal para o modelo, muitas vezes incorporando o "persona" (ex: "Você é um médico intensivista...") e o formato de saída desejado.
    *   `extra_args`: Argumentos adicionais para o `gemx.sh gen`, como `--max-output-tokens`.
*   **Exemplos de Automações Médicas Incluídas**:
    *   **`sepse_bundle.yaml`**: Gera um bundle inicial de sepse para UPA, incluindo triagem, ABCDE, coleta, antibióticos empíricos (com campos obrigatórios para fármacos), ressuscitação volêmica, vasopressores e critérios de encaminhamento.
        *   **Exemplo de Uso**: `./gemx.sh auto run automations/sepse_bundle.yaml --prompt "Paciente com 70 anos, febre, hipotensão, lactato 4.0."`
    *   **`ira_aki.yaml`**: Abordagem de Injúria Renal Aguda (IRA/AKI) na UPA, cobrindo classificação KDIGO, avaliação hemodinâmica, ajustes de medicação nefrotóxica e manejo de distúrbios eletrolíticos.
        *   **Exemplo de Uso**: `./gemx.sh auto run automations/ira_aki.yaml --prompt "Paciente com creatinina de 2.5, basal 0.8, oligúrico."`
    *   **`hda_triage.yaml`**: Protocolo de Hemorragia Digestiva Alta (HDA) para UPA, com estratificação de risco (Glasgow-Blatchford, Rockall), farmacoterapia inicial e indicações de endoscopia.
    *   **`ventilacao_mecanica.yaml`**: Protocolo prático de Ventilação Mecânica Inicial (UPA/ITU), abordando indicações, escolha do modo, parâmetros iniciais por fenótipo e sedoanalgesia.
    *   **`broncoespasmo_seco.yaml`**: Manejo de broncoespasmo grave, incluindo avaliação, nebulização, corticoides, sulfato de magnésio e terbutalina.
    *   **`rx_brief.yaml`**: Um template genérico para obter informações detalhadas sobre fármacos (Apresentação, Diluição, Posologia, etc.).
    *   **`sgarbossa_check.yaml`**: Explica os critérios de Sgarbossa para diagnóstico de IAM em presença de BRE/MP.
*   **`batch_from_file.sh`**: Um script utilitário para executar múltiplas automações a partir de uma lista de prompts em um arquivo, ideal para processamento em lote ou simulações.
    *   **Uso**: `./automations/batch_from_file.sh <arquivo_de_prompts.txt>`
*   **Como Criar Novas Automações**: A estrutura `.yaml` é intuitiva. Profissionais podem facilmente adaptar automações existentes ou criar novas para atender a necessidades específicas, definindo o prompt, o modelo e os argumentos.

### 4. Monitoramento e Análise de Uso

A capacidade de auditar e analisar o uso do Gemini é crucial para otimização e conformidade.

*   **`gemx-logs.sh` (Navegador de Logs Interativo)**: Este script permite explorar os logs de auditoria (`audit-*.jsonl`) gerados pelo `gemx`.
    *   **Funcionalidades**: Utiliza `fzf` (se disponível) para uma interface interativa de busca e visualização, permitindo filtrar por timestamp, evento, comando e modelo.
    *   **Detalhes**: Exibe o conteúdo JSON completo de cada entrada de log, facilitando a depuração e a compreensão do que foi executado.
    *   **Uso**: `./gemx-logs.sh`
*   **`gemx-stats.sh` (Estatísticas Textuais Rápidas)**: Gera um resumo estatístico conciso dos logs de auditoria em formato de texto.
    *   **Métricas**: Contagem por evento (start/finish/cancel), top comandos, modelos mais usados, duração média por comando e série temporal diária.
    *   **Parâmetros**: Suporta `--since` e `--until` para filtrar por período, e `--top N` para limitar os resultados.
    *   **Uso**: `./gemx-stats.sh --since 2025-09-01 --top 5`
*   **`gemx-stats-html.py` (Dashboards Visuais Poderosos)**: Um script Python que transforma os logs de auditoria em um dashboard HTML interativo e visualmente rico.
    *   **Geração de Gráficos**: Utiliza `matplotlib` para criar gráficos de barras e linhas que visualizam:
        *   Eventos por tipo.
        *   Top comandos executados.
        *   Modelos Gemini utilizados.
        *   Duração média das execuções por comando.
        *   Série diária de finalizações de comandos.
    *   **Saída HTML**: Gera um arquivo `index.html` e ativos de imagem (`.png`) em um diretório de saída configurável, pronto para ser visualizado em qualquer navegador.
    *   **Uso**: `./gemx-stats-html.py --since 2025-09-01 --out-dir ./relatorio_clinico`

### 5. Templates de Prompt (Diretório `templates/`)

Embora o `README.md` neste diretório seja conciso, ele aponta para a existência de templates de prompt que são fundamentais para a estruturação das respostas do Gemini. Estes templates são referenciados pelas automações e podem ser personalizados via `~/.config/gemx/config.json`.

*   **`rx`**: Para condutas estruturadas de fármacos.
*   **`brief`**: Para resumos concisos em bullets.
*   **`sgarbossa`**: Para critérios específicos de diagnóstico.
*   **`hda`**: Para fluxos de atendimento.

## Integração com `direnv`

O `direnv` é uma ferramenta essencial para o Megapack v2. O arquivo `.envrc` no diretório raiz do Megapack garante que, ao entrar no diretório, as variáveis de ambiente e os aliases necessários sejam automaticamente carregados. Isso cria um ambiente de trabalho isolado e consistente, sem a necessidade de comandos `source` manuais.

## Personalização e Extensibilidade

O Gemini Megapack v2 é projetado para ser adaptável.
*   **Automações Personalizadas**: Crie seus próprios arquivos `.yaml` no diretório `automations/` para desenvolver protocolos e fluxos de trabalho específicos para sua instituição ou especialidade.
*   **Configuração do `gemx`**: Edite `~/.config/gemx/config.json` para ajustar modelos padrão, temperaturas e outros parâmetros globais do `gemx`.
*   **Scripts Adicionais**: Integre seus próprios scripts shell ou Python para estender as funcionalidades do Megapack.

## Casos de Uso e Benefícios Clínicos

O potencial do Gemini Megapack v2 no ambiente clínico é vasto:

*   **Suporte à Decisão em Emergências**: Geração rápida de protocolos para condições críticas (sepse, IAM, AVC, IRA), garantindo que nenhum passo essencial seja esquecido.
*   **Educação e Treinamento**: Ferramenta interativa para estudantes e residentes aprenderem e revisarem protocolos clínicos.
*   **Otimização de Fluxos de Trabalho**: Automatização da criação de resumos de casos, planos de tratamento iniciais ou informações detalhadas sobre fármacos.
*   **Padronização de Condutas**: Ajuda a garantir a adesão a diretrizes clínicas e a padronizar a qualidade do atendimento.
*   **Pesquisa e Análise**: As ferramentas de logging e reporting podem ser usadas para analisar padrões de uso, identificar lacunas no conhecimento ou otimizar a interação com a IA.

## Comunidade e Contribuição

O Gemini Megapack v2 é um projeto vivo. Encorajamos a comunidade médica e de desenvolvedores a contribuir com novas automações, melhorias nos scripts existentes, documentação e feedback. Sua experiência é inestimável para moldar o futuro desta plataforma.

## Próximos Passos: Sua Jornada Começa Agora

1.  **Clone o Repositório**: Obtenha a versão mais recente do Gemini Megapack v2.
2.  **Instale as Dependências**: Execute o script de instalação apropriado para seu sistema operacional (`./install.sh`, `./install-macos.sh` ou `./install-ubuntu.sh`).
3.  **Ative o `direnv`**: Se ainda não o fez, permita o `direnv` no diretório do Megapack (`direnv allow .`).
4.  **Faça Login no Gemini CLI**: Autentique-se com sua conta Google usando `./gemx.sh login`.
5.  **Explore e Experimente**: Comece a usar as automações existentes e sinta o poder da inteligência clínica.

## Aviso Legal e Ético

É crucial lembrar que o Gemini Megapack v2 é uma ferramenta de suporte e não substitui o julgamento clínico de um profissional de saúde qualificado. As informações geradas pela IA devem ser sempre revisadas, validadas e adaptadas ao contexto específico de cada paciente. A responsabilidade final pela decisão clínica e pelo cuidado do paciente recai sempre sobre o profissional.

---
**Gemini Megapack v2** — *Inteligência Artificial a Serviço da Saúde.*

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
