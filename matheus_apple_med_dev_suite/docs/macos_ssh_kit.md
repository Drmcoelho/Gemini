# Documentação: `macos/ssh_kit`

O `macos/ssh_kit` é um conjunto de ferramentas e scripts projetado para criar uma experiência de desenvolvimento e administração de sistemas robusta e segura no macOS.

## Componentes Principais

### 1. Scripts de SSH e Segurança

Localizados em `scripts/`, estes scripts automatizam tarefas comuns de segurança de SSH:

- `macos_ssh_bootstrap.sh`: Prepara a estrutura de diretórios `~/.ssh/config.d/` e valida a instalação do OpenSSH.
- `generate_ed25519.sh`: Gera uma chave SSH padrão (Ed25519) e a adiciona ao `ssh-agent` e ao Keychain do macOS.
- `generate_fido2.sh`: Gera uma chave de segurança FIDO2/U2F (ex: YubiKey, TouchID), que oferece uma camada extra de segurança.
- `enable_sshd_macos.sh`: Ativa o servidor SSH no macOS.
- `harden_sshd_macos.sh`: Aplica uma configuração de segurança mais restritiva ao `sshd`, desabilitando senhas e permitindo apenas autenticação por chave pública.

### 2. `medcli` - CLI para APIs Médicas

O `medcli` é uma poderosa ferramenta de linha de comando em Python para interagir com APIs de saúde.

- **Instalação**: `pipx install .` dentro do diretório `macos/ssh_kit/medcli`.
- **Comandos**:
    - `med fhir get <base_url> <path>`: Consulta servidores FHIR.
    - `med openfda query <endpoint> <search_query>`: Consulta a API OpenFDA.
    - `med rxnorm <subcommand> <args>`: Interage com a API RxNorm para informações de medicamentos.
    - `med ctgov search <query>`: Busca estudos no ClinicalTrials.gov.
    - `med obsidian patient ...`: Cria notas no Obsidian a partir de dados de pacientes em um servidor FHIR.
    - `med card drug <name>`: Gera um "card" de medicamento em Markdown.
    - `med plots obs ...`: Gera gráficos de séries temporais para observações FHIR.

### 3. `sshx` - Lançador de Conexões SSH

Localizado em `bin/sshx`, o `sshx` é um lançador de conexões SSH interativo que usa `fzf` para permitir a busca rápida em seu histórico de conexões e no inventário de hosts.

- **Inventário**: Os hosts podem ser definidos no arquivo `inventory/hosts.yml`, com tags e roles, permitindo buscas filtradas como `sshx --tag db`.
- **Fallback**: Se `fzf` não estiver instalado, ele usa um menu de seleção padrão.

### 4. Túneis Automatizados

O kit fornece múltiplas maneiras de automatizar túneis SSH:

- **`bin/ssh-tunnel`**: Um script de loop que usa `autossh` (se disponível) para manter um túnel persistente.
- **`launchagents/`**: Contém um exemplo de `plist` para carregar o `ssh-tunnel` como um serviço do sistema via `launchd`, garantindo que ele inicie no login.
- **`hammerspoon/`**: Um script para o [Hammerspoon](https://www.hammerspoon.org/) que monitora quais aplicativos estão ativos. Ele pode, por exemplo, iniciar um túnel para o banco de dados automaticamente sempre que você abrir o TablePlus ou o VSCode, e derrubá-lo quando os aplicativos forem fechados.

### 5. Integração com VPN

A pasta `vpn/` contém scripts para facilitar o uso de **Tailscale** e **ZeroTier**, incluindo a aplicação de políticas de ACL (Access Control List) para o Tailscale.

### 6. SwiftUI e Atalhos

- **`swift/`**: Contém código-fonte para dois pequenos aplicativos SwiftUI:
    - `MedPanel`: Uma interface gráfica simples para executar comandos do `medcli`.
    - `MenuBarTunnels`: Um aplicativo de barra de menus para gerenciar túneis SSH.
- **`shortcuts/`**: Exemplos e guias para integrar os scripts com o aplicativo **Atalhos** do macOS, permitindo que você execute tarefas complexas com um clique ou comando de voz.
