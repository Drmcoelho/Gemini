# SECURITY.md

## Regras práticas
- **Sempre** use passphrase forte para chaves privadas (Keychain lembra por você).
- Prefira `ed25519` para chaves clássicas e `ed25519-sk` para FIDO2.
- Ative **2FA** em todos os provedores remotos (GitHub, GitLab, etc.).
- Para servidores expostos, combine com firewall (pf, Little Snitch) e ban por falha (fail2ban sidecar em Linux).
- **Backup**: exporte apenas a **pública**; a privada permanece local. Para FIDO2, mantenha **2ª chave** (backup).
