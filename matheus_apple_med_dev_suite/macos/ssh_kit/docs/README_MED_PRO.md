# Apple SSH + Medical Pro Kit (Obsidian + APIs + pipx)

## Novidades
- **medcli** (pipx): `med` para FHIR/OpenFDA/RxNorm/CTGov + geradores de cards Markdown e ponte Obsidian.
- **Obsidian bridge**: `med obsidian patient --base ... --pid ... --vault "$HOME/Obsidian/Vault"`
- **Dicionários**: `med dicts init/import-*` → `med-dicts.sqlite` (LOINC/RxNorm/SNOMED com CSVs fornecidos por você).
- **Shortcut/AppleScript**: DrugCard que copia um **card Markdown** pro clipboard.
- **Automação**: LaunchAgent para sync diário de Patient→Obsidian.

## pipx install
```bash
cd medcli
pipx install .   # cria "med"
med --help
```

## Observações legais e de privacidade
- **SNOMED CT** pode ter restrições de licença no seu país. Não distribuímos dados; o importador só lê **CSVs preparados por você**.
- **LOINC** é disponibilizado sob licença própria — baixe do site oficial e aceite os termos.
- Nunca exporte **PHI** para serviços públicos. Para produção, use **servidores privados** e redes seguras (Tailscale/ZeroTier).
