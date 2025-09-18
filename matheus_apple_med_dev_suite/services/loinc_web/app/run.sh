#!/usr/bin/env bash
set -euo pipefail
export DB_PATH="${DB_PATH:-/data/loinc.sqlite}"
uvicorn app:app --host 0.0.0.0 --port 8080
