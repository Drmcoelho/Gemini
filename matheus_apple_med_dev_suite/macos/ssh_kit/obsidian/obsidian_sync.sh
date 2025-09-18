#!/usr/bin/env bash
# Sync a Patient summary into Obsidian using medcli
set -euo pipefail
: "${FHIR_BASE:?defina FHIR_BASE}"
: "${PATIENT_ID:?defina PATIENT_ID}"
: "${OB_VAULT:?defina OB_VAULT (pasta do vault)}"
med obsidian patient --base "$FHIR_BASE" --pid "$PATIENT_ID" --vault "$OB_VAULT"
