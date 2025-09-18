#!/usr/bin/env bash
# ctgov_cli.sh — consulta ClinicalTrials.gov v2 API.
# ./ctgov_cli.sh 'query.term=sepsis&page.size=5&fields=BriefTitle,StudyType'
set -euo pipefail
QS="${1:-query.term=sepsis&page.size=5&fields=BriefTitle,StudyType,LeadSponsorName}"
curl -sS "https://clinicaltrials.gov/api/v2/studies?${QS}" | jq .
