# Automations — Guia Rápido

Cada arquivo `.yaml/.json` descreve uma automação executável pelo wrapper:
```bash
./gemx.sh auto run automations/<arquivo>.yaml
```

## Incluídas

- **sepse_bundle.yaml** — Bundle inicial de sepse (UPA), com antibióticos + vasopressores (campos completos por droga).
- **hda_triage.yaml** — Protocolo de HDA com estratificação e farmacoterapia.
- **ira_aki.yaml** — Abordagem de IRA/AKI (KDIGO, volemia, ajustes, hipercalemia/hiponatremia).
- **ventilacao_mecanica.yaml** — VM inicial por fenótipo, sedoanalgesia, desmame.
- **broncoespasmo_seco.yaml** — Manejo de broncoespasmo em período de seca.

> Dica: personalize as doses e listas de fármacos conforme seu formulário institucional.
