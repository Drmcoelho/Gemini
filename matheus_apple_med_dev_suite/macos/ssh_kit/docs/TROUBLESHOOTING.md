# TROUBLESHOOTING.md

## FIDO2 não aparece em `ssh -Q key`
- Instale `openssh` e `libfido2` via Homebrew e garanta `PATH=/opt/homebrew/bin:$PATH` (Apple Silicon).
- Reabra o terminal para renovar o `ssh-agent`.

## `verify-required` falha sem prompt de toque
- Confirme que a chave foi criada com `-O verify-required` e que você realmente tocou o dispositivo.
- Algumas U2F antigas não suportam modo resident; remova `-O resident` e gere novamente.

## `permission denied (publickey)`
- Confirme `IdentityFile` correto no bloco `Host` e `IdentitiesOnly yes`.
- Verifique permissões: `chmod 700 ~/.ssh` e `chmod 600 ~/.ssh/*`.
- No servidor, `~/.ssh/authorized_keys` deve ter `0600` e o `~/.ssh` `0700`.
