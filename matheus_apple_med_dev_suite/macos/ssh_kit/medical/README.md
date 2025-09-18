# Integrações Médicas (Open Source)

> **Aviso**: Use apenas **dados não-identificáveis**. Não suba **PHI** para serviços externos sem acordo formal (BAA) e avaliação de risco. Estes exemplos são para pesquisa, educação e prototipagem.

## FHIR (HAPI FHIR)
```bash
medical/fhir/fhir_cli.sh https://hapi.fhir.org/baseR4 "Patient?_count=3"
medical/fhir/fhir_cli.sh https://hapi.fhir.org/baseR4 "Observation?code=loinc|718-7&_count=3"
```

## OpenFDA (drugs)
```bash
medical/openfda/openfda_drug.sh label 'openfda.brand_name:"metformin"'
medical/openfda/openfda_drug.sh event 'patient.reaction.reactionmeddrapt:"anaphylactic reaction"'
```

## RxNorm (RxNav)
```bash
medical/rxnorm/rxnorm_cli.sh rxcui "amoxicillin"
medical/rxnorm/rxnorm_cli.sh properties 723
medical/rxnorm/rxnorm_cli.sh interactions 723
```

## ClinicalTrials.gov v2
```bash
medical/clinicaltrials/ctgov_cli.sh 'query.term=sepsis&page.size=5&fields=BriefTitle,OverallStatus'
```

## Automação diária
```bash
medical/cron/install_refresh.sh
# editar tópico:
launchctl unload ~/Library/LaunchAgents/com.mgx.med.ctgov.refresh.plist
# ajuste o TOPIC dentro do plist (ou crie uma cópia) e load novamente
launchctl load ~/Library/LaunchAgents/com.mgx.med.ctgov.refresh.plist
```

## Segurança e Conformidade
- **Sem PHI**: mantenha tudo anônimo. Se precisar de dados clínicos reais, use um **FHIR server** privado controlado (ex: HAPI FHIR self-hosted) e redes privadas (Tailscale/ZeroTier).
- **Logs**: scripts geram logs via `launchctl`; revise permissões e rotação.
- **Apple Keychain**: chaves SSH ficam com passphrase guardada no Keychain; não suba chaves sem criptografia.
