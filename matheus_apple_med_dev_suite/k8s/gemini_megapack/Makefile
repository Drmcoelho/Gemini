# Makefile — docker & k8s helpers
IMAGE ?= gemini-megapack:latest
REGISTRY ?= ghcr.io/your-org/gemini-megapack

.PHONY: build run push up down k8s-apply k8s-delete

build:
\tdocker build -t $(IMAGE) .

run:
\tdocker run --rm -it -p 8080:8080 -e WEB_USER=admin -e WEB_PASS=change -v gemx_config:/home/app/.config/gemx $(IMAGE)

push:
\tdocker tag $(IMAGE) $(REGISTRY)
\tdocker push $(REGISTRY)

up:
\tdocker compose up -d --build

down:
\tdocker compose down

k8s-apply:
\tkubectl apply -f k8s/pvc.yaml
\tkubectl apply -f k8s/secret.yaml
\tkubectl apply -f k8s/deploy.yaml

k8s-delete:
\tkubectl delete -f k8s/deploy.yaml || true
\tkubectl delete -f k8s/secret.yaml || true
\tkubectl delete -f k8s/pvc.yaml || true

# --- Helm & Terraform helpers ---
.PHONY: helm-install helm-uninstall tf-init tf-apply tf-destroy

helm-install:
	helm dependency update charts/gemx
	helm upgrade --install gm charts/gemx -f charts/gemx/values-gke.yaml

helm-install-traefik:
	helm dependency update charts/gemx
	helm upgrade --install gm charts/gemx -f charts/gemx/values-traefik.yaml

helm-uninstall:
	helm uninstall gm || true

tf-init:
	cd infra/terraform/gke && terraform init

tf-apply:
	cd infra/terraform/gke && terraform apply -auto-approve

tf-destroy:
	cd infra/terraform/gke && terraform destroy -auto-approve
