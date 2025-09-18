.PHONY: help ### suite targets
help:
	@echo "Targets:"
	@echo "  macos-provision     # Install brew+fzf+autossh+tailscale/zerotier (interactive)"
	@echo "  loinc-import        # Import LOINC CSV -> SQLite"
	@echo "  loinc-run           # Run FastAPI locally (uvicorn)"
	@echo "  loinc-docker        # Build+run loinc-web docker-compose"
	@echo "  helm-loinc-install  # Helm install loinc-web"
	@echo "  helm-gemx-install   # Helm install gemx"
	@echo "  tf-gke-apply        # Terraform GKE Autopilot cluster (from gemini_megapack)"

macos-provision:
	cd macos/ssh_kit && ./provision/provision_macos.sh || true

loinc-import:
	@[ -n "$$CSV" ] || (echo "Usage: make loinc-import CSV=/path/LoincTableCore.csv"; exit 2)
	python3 services/loinc_web/scripts/loinc_import.py --csv "$$CSV" --db services/loinc_web/data/loinc.sqlite

loinc-run:
	cd services/loinc_web/app && DB_PATH=../data/loinc.sqlite uvicorn app:app --reload --port 8080

loinc-docker:
	cd services/loinc_web && docker build -t loinc-web:latest .
	cd services/loinc_web && docker compose up -d

helm-loinc-install:
	helm upgrade --install loinc charts/loinc-web

helm-gemx-install:
	helm dependency update charts/gemx || true
	helm upgrade --install gm charts/gemx -f k8s/gemini_megapack/charts/gemx/values-gke.yaml

tf-gke-apply:
	cd k8s/gemini_megapack/infra/terraform/gke && terraform init && terraform apply -auto-approve
