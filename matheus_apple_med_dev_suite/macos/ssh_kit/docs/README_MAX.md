# Max pack: gráficos, sync bidirecional e painel SwiftUI

## Plots (FHIR Observations → PNG)
```bash
med plots obs --base https://hapi.fhir.org/baseR4 \
  --patient 123 --code 718-7 --out_png lactate.png --title "Lactate"
./obsidian/embed_plot.sh "$HOME/Obsidian/MedVault/Patients/John Doe — 123.md" lactate.png
```

## Sync bidirecional (Markdown ↔ FHIR)
Crie `Plan.md` com frontmatter:
```yaml
---
careplan:
  title: "Sepsis bundle"
  notes: "Early goal-directed therapy"
  activities:
    - "Fluid resuscitation"
    - "Lactate monitoring"
orders:
  - code: "LAB:LACTATE"
    text: "Arterial lactate"
---
```
Envie ao FHIR:
```bash
med mdfhir md2fhir Plan.md --base https://hapi.fhir.org/baseR4 --patient 123
```
Baixe do FHIR (primeiro CarePlan + todos ServiceRequests) para Markdown:
```bash
med mdfhir fhir2md --base https://hapi.fhir.org/baseR4 --patient 123 --out_md Plan.md
```

## MedPanel (SwiftUI)
- Código em `swift/MedPanel/MedPanel.swift`; abre no Xcode, crie o projeto e vincule o arquivo.
- O app chama o CLI `med` e mostra a saída (rápido para testes e demonstrações).

> Observação: Em ambiente clínico real, faça autenticação, logging e **não** use servidores públicos.
