# macOS SSH Kit (Apple-first)

Kit opinativo e **robusto** para cliente/servidor SSH no macOS — com Keychain, FIDO2 (YubiKey/TouchID quando suportado), hardening do sshd e utilitários.

## Instalação rápida
```bash
# unpack e bootstrap
./scripts/macos_ssh_bootstrap.sh

# gerar chave clássica (recomendado para Git/GitHub)
./scripts/generate_ed25519.sh

# opcional: gerar chave FIDO2 (exige OpenSSH com libfido2)
./scripts/generate_fido2.sh

# opcional: ativar sshd no macOS (servidor)
./scripts/enable_sshd_macos.sh
./scripts/harden_sshd_macos.sh
```

## Requisitos e notas
- macOS 12+ recomendado.
- FIDO2 (chaves `-sk`): precisa de `openssh` com `libfido2`. Cheque com `ssh -Q key | grep sk-`.
  - Se não aparecer, instale via Homebrew: `brew install openssh libfido2` e ajuste `PATH`.
- `UseKeychain yes` salva **a senha da chave** no **Keychain**, não o arquivo da chave.

## Publicar chave em servidores
```bash
./scripts/ssh_copy_id.sh user@host ~/.ssh/id_ed25519.pub
```

## Hardening (servidor macOS)
- `PasswordAuthentication no` e `AuthenticationMethods publickey` (somente chaves).
- `PermitRootLogin no` (sem root direto).
- Limite grupos/usuários conforme necessário.
- Reinício do daemon com `launchctl kickstart`.

## Exemplos de `~/.ssh/config`
Veja `ssh/config.d/`:
- `00-global.conf`: Defaults seguros + multiplexing (ControlPersist).
- `10-github.conf`: GitHub.
- `20-examples.conf`: JumpHost e FIDO2.

## Touch ID para sudo (opcional, manual)
Consulte `pam/touchid/README.md`.
