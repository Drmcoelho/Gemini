# Gemini (`gemx.sh`)

`gemx.sh` é um wrapper para o CLI oficial do Gemini, projetado para melhorar a experiência do usuário com menus, automações, perfis e templates.

## Filosofia

- **Sempre `gemini-2.5-pro`**: `gemx.sh` força o uso do modelo `gemini-2.5-pro` por padrão para garantir a melhor qualidade de resposta.
- **Foco na Experiência do Usuário**: O script foi projetado para ser fácil de usar, com menus interativos e comandos intuitivos.

## Instalação e Configuração

### Dependências

- **`jq`**: Para manipulação de JSON.
- **`yq`**: Para manipulação de YAML.
- **`gemini` ou `gmini`**: O CLI oficial do Gemini.

### Configuração

- **`GEMINI_BIN`**: A variável de ambiente `GEMINI_BIN` pode ser usada para especificar o caminho para o binário do Gemini.
- **`GEMX_HOME`**: A variável de ambiente `GEMX_HOME` pode ser usada para especificar o diretório de configuração do `gemx.sh`. O padrão é `~/.config/gemx`.
- **`config.json`**: O arquivo de configuração principal, localizado em `$GEMX_HOME/config.json`.

## Uso

### Comandos

- **`menu`**: Abre o menu interativo.
- **`chat`**: Inicia um loop de chat interativo.
- **`gen`**: Gera uma resposta única para um prompt.
- **`vision`**: Gera uma resposta para um prompt com uma imagem.
- **`tpl`**: Gerencia os templates.
- **`profile`**: Gerencia os perfis.
- **`auto`**: Gerencia as automações.
- **`others`**: Abre o menu `others.json`.

## Configuração (`config.json`)

O arquivo `config.json` permite personalizar o comportamento do `gemx.sh`.

- **`model`**: O modelo a ser usado.
- **`stream`**: Se deve ou não usar o modo de streaming.
- **`temperature`**: A temperatura a ser usada.
- **`system`**: A mensagem de sistema a ser usada.
- **`project`**: O ID do projeto do Google Cloud.
- **`plugins`**: As configurações dos plugins.
- **`profiles`**: Os perfis de configuração.
- **`templates`**: Os templates de prompt.

## Perfis

Os perfis permitem alternar rapidamente entre diferentes configurações.

- **`med`**: Perfil para assistência médica.
- **`code`**: Perfil para programação.
- **`draft`**: Perfil para rascunhos.

## Templates

Os templates permitem reutilizar prompts.

- **`rx`**: Formata condutas em tópicos.
- **`brief`**: Resume em 5 bullets.
- **`sgarbossa`**: Explica os critérios de Sgarbossa.
- **`hda`**: Fluxo de suspeita de hemorragia digestiva alta.

## Automações

As automações permitem executar tarefas complexas com um único comando.

- **`rx_brief.yaml`**: Gera um resumo de prescrição médica.
- **`sgarbossa_check.yaml`**: Explica os critérios de Sgarbossa.
- **`batch_from_file.sh`**: Processa prompts em lote a partir de um arquivo.

## `others.json`

O arquivo `others.json` define um catálogo de extensões, plugins, interações e automações.

- **`extensions`**: Extensões para o `gh` CLI.
- **`plugins`**: Plugins para o `gemx.sh`.
- **`interactions`**: Prompts e templates predefinidos.
- **`automations`**: Automações.

## Estendendo `gemx.sh`

- **Adicionar novos templates**: Adicione uma nova entrada ao objeto `templates` no `config.json`.
- **Adicionar novos perfis**: Adicione uma nova entrada ao objeto `profiles` no `config.json`.
- **Adicionar novas automações**: Crie um novo arquivo YAML, JSON ou shell script no diretório `automations`.
- **Adicionar novas entradas ao `others.json`**: Edite o arquivo `others.json` para adicionar novas extensões, plugins, interações ou automações.

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
