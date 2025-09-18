# Apple Shortcuts — Integração

Você pode criar atalhos no app **Atalhos** e invocá-los via CLI:
```bash
shortcuts run "Start DB Tunnel" --input "HOST=clinic-vm LPORT=5432 RHOST=127.0.0.1 RPORT=5432"
```
Incluímos um wrapper que chama o `ssh-tunnel` diretamente — use como fallback quando não quiser Shortcuts.
Arquivos `.shortcut` são binários — crie-os manualmente seguindo este guia.
