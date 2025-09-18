# Touch ID para `sudo` (macOS)

> **Atenção**: alteração de PAM; faça com cuidado.

1. Edite `/etc/pam.d/sudo` e **adicione no topo**:
   ```
   auth       sufficient     pam_tid.so
   ```
2. Salve, teste com `sudo -k` e `sudo true` — deve solicitar Touch ID.
3. Se algo der errado, volte o arquivo ao original.

Isso não afeta SSH diretamente, mas melhora UX de comandos administrativos.
