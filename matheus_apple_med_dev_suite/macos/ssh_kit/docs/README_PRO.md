# Apple SSH Pro Kit

Este pacote expande o kit básico com:

- **VPNs**: scripts e exemplos para **Tailscale** e **ZeroTier**.
- **FZF/Zsh**: `sshx` — seletor de hosts via FZF (ou fallback interativo).
- **Túneis automáticos**:
  - `ssh-tunnel` (loop/autossh) + **LaunchAgents** (start at login).
  - **Hammerspoon**: inicia/para túneis conforme apps são ativados/fechados.
- **Provisioning** para múltiplos Macs (brew + pacotes + cópia de binários).

## Quickstart (incremental ao kit base)
```bash
# 1) VPN (opcional)
./vpn/tailscale_up.sh --ssh
./vpn/tailscale_status.sh
# ou
./vpn/zerotier_join.sh <NETWORK_ID>

# 2) FZF launcher
./provision/provision_macos.sh   # instala fzf, hammerspoon, autossh (opcional)
cat shell/.zshrc.sshx >> ~/.zshrc

# 3) Start automático de túnel ao logar
./launchagents/install_tunnel_agent.sh db HOST=clinic-vm LPORT=5432 RHOST=127.0.0.1 RPORT=5432

# 4) App-aware (Hammerspoon)
cp hammerspoon/init.lua ~/.hammerspoon/init.lua
open -a Hammerspoon
```

## Segurança
- Tailscale SSH aceita login com chaves **ou** ACLs TS; revise sua policy no admin da Tailscale.
- Em ZeroTier, **autorize** o nó no controlador antes de liberar serviços.
- Use chaves FIDO2 (`ed25519-sk`) para hosts críticos (com `verify-required`).

## Dicas
- `sshx` suporta `--` para rodar um comando remoto após selecionar o host:
  ```bash
  sshx -- 'uname -a && whoami'
  ```
- Para perfis por diretório de projeto, combine com `.envrc` (direnv) e aliases contextuais.

---

## Inventory + Tags/Roles (sshx)
- Edite `inventory/hosts.yml` (tags, roles, groups).
- Filtros:
  ```bash
  sshx --tag db
  sshx --role etl
  sshx --group clinic
  ```

## Shortcuts
- Use `shortcuts run "Start DB Tunnel" --input "HOST=... LPORT=... RHOST=... RPORT=..."`.
- Wrapper: `shortcuts/run_shortcut.sh`.

## Tailscale ACLs
- `vpn/tailscale_acl.example.json` + `vpn/tailscale_apply_acl.sh` (requer `TS_API_KEY`/`TS_TAILNET`).

## Menu bar app (SwiftUI)
- Código em `swift/MenuBarTunnels/` (abra no Xcode, personalize seus túneis).

## Medical APIs
- Wrappers em `medical/` (FHIR, OpenFDA, RxNorm, ClinicalTrials).  
  *Somente dados não-identificáveis.*
