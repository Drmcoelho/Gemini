# Matheus Apple Med Dev Suite (unified)

## Conteúdo
- `macos/ssh_kit/` — suite Apple-first (SSH/FIDO2, VPNs, FZF launcher, Hammerspoon, medcli, Obsidian, plots, MD↔FHIR, Shortcuts).
- `services/loinc_web/` — **LOINC Web** (FastAPI + SQLite/FTS5) com Docker/Compose/Helm.
- `k8s/gemini_megapack/` — Helm/Terraform (GKE Autopilot, Traefik, cert-manager) para apps web.
- `charts/` — atalhos dos charts principais (`gemx`, `loinc-web`).

## Uso rápido
```bash
# 1) macOS — provisionar (opcional, interativo)
make macos-provision

# 2) LOINC: importar CSV (baixe no site oficial da Regenstrief)
make loinc-import CSV=/caminho/LoincTableCore.csv

# 3) Subir a UI local
make loinc-run
# http://localhost:8080

# 4) Docker/Compose
make loinc-docker

# 5) Helm (K8s)
make helm-loinc-install
make helm-gemx-install    # instala chart gemx do megabundle
```

> Nota legal: não distribuímos dados sensíveis nem bases licenciadas. LOINC deve ser baixado do site oficial sob seus termos.
