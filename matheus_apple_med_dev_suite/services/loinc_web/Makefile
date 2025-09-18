.PHONY: venv import run docker-up docker-build helm-install helm-uninstall

venv:
	python3 -m venv .venv && . .venv/bin/activate && pip install -r app/requirements.txt

import:
	python scripts/loinc_import.py --csv "$$CSV" --db ./data/loinc.sqlite

run:
	cd app && DB_PATH=../data/loinc.sqlite uvicorn app:app --reload --port 8080

docker-build:
	docker build -t loinc-web:latest .

docker-up:
	docker compose up -d

helm-install:
	helm upgrade --install loinc charts/loinc-web

helm-uninstall:
	helm uninstall loinc || true
