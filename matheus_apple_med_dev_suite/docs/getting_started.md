# Guia de Início Rápido (Getting Started)

Este guia orienta você na configuração completa da **Matheus Apple Med Dev Suite** em um ambiente macOS.

## Passo 1: Pré-requisitos

Certifique-se de que você tem o **Homebrew** instalado. Se não, instale-o com:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Passo 2: Provisionamento do Ambiente Local

O `Makefile` na raiz do projeto simplifica a instalação das dependências e ferramentas locais.

1.  **Execute o Target de Provisionamento:**
    Este comando usa o Homebrew para instalar as dependências essenciais (`jq`, `yq`, `direnv`, `fzf`, `autossh`) e ferramentas recomendadas (`tailscale`, `zerotier-one`).

    ```bash
    make macos-provision
    ```

2.  **Instale o Gemini CLI:**
    O `gemx.sh` é um wrapper para o CLI oficial do Google. O script de instalação tentará instalá-lo via Homebrew ou `npm`.

    ```bash
    # O script de instalação do megapack lida com isso
    cd k8s/gemini_megapack
    ./install.sh
    ```

3.  **Ative o `direnv`:**
    O `direnv` gerencia variáveis de ambiente por diretório. O script de instalação adiciona o hook necessário ao seu `~/.zshrc` ou `~/.bashrc`. Para ativá-lo, abra um novo terminal ou execute:

    ```bash
    source ~/.zshrc  # ou source ~/.bashrc
    ```

    Navegue até o diretório do projeto e permita que o `direnv` carregue o ambiente:
    ```bash
    direnv allow .
    ```

## Passo 3: Login e Verificação

Com o ambiente configurado, faça o login na sua Conta Google para autenticar o Gemini CLI.

```bash
# Navegue até a pasta do megapack
cd k8s/gemini_megapack

# Execute o login via gemx.sh
./gemx.sh login
```

Isso abrirá um navegador para autenticação. Após o sucesso, verifique sua identidade:

```bash
./gemx.sh whoami
```

## Passo 4: Instalando o `medcli`

O `medcli` é a ferramenta para interagir com APIs médicas. Ele é projetado para ser instalado em um ambiente isolado usando `pipx`.

1.  **Instale `pipx`:**
    ```bash
    brew install pipx
    pipx ensurepath
    ```

2.  **Instale o `medcli`:**
    ```bash
    cd ../../macos/ssh_kit/medcli/
    pipx install .
    ```

3.  **Verifique a Instalação:**
    ```bash
    med --help
    ```

## Passo 5: Executando os Serviços

### LOINC Web Service (via Docker)

1.  **Baixe os Dados LOINC:**
    - Visite [loinc.org](https://loinc.org/downloads/loinc/) e baixe o arquivo `LoincTableCore.csv`.

2.  **Importe os Dados:**
    O `Makefile` na raiz do projeto possui um atalho para isso. Execute a partir da raiz:
    ```bash
    make loinc-import CSV=/caminho/para/seu/LoincTableCore.csv
    ```

3.  **Suba o Serviço com Docker Compose:**
    ```bash
    make loinc-docker
    ```
    O serviço estará disponível em `http://localhost:8088`.

### Gemini Megapack Web UI (via Docker)

1.  **Navegue até a pasta do megapack:**
    ```bash
    cd k8s/gemini_megapack
    ```

2.  **Suba os Serviços com Docker Compose:**
    ```bash
    docker compose up -d
    ```
    A interface web estará disponível em `http://localhost:8080`.

## Conclusão

Seu ambiente agora está totalmente configurado. Você pode:
- Usar o `gemx.sh` para executar automações de IA.
- Usar o `medcli` para buscar dados médicos.
- Acessar os serviços web locais.

Consulte as outras páginas da documentação para explorar cada componente em profundidade.
