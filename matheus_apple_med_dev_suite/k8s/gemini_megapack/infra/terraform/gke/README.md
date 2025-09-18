# Terraform — GKE Autopilot + Helm (cert-manager, Traefik, gemx) + DNS

## Pré-requisitos
- `gcloud auth application-default login`
- Projeto GCP com billing ativado
- Terraform >= 1.5
- Permissões: Container Admin, DNS Admin (se `create_zone=true`)

## Uso
```bash
cd infra/terraform/gke
cp terraform.tfvars.example terraform.tfvars
# Edite project_id, domain, oauth, etc.

terraform init
terraform apply -auto-approve

# kubeconfig gerado em ./kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get pods -A
```

## DNS
Se `create_zone=false`, aponte `A`/`CNAME` do seu domínio para o LB do Ingress após o deployment.
