provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "services" {
  for_each = toset([
    "container.googleapis.com",
    "dns.googleapis.com",
    "certificatemanager.googleapis.com"
  ])
  service = each.value
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  deletion_protection = false

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {}
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host  = "https://${google_container_cluster.gke.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.gke.endpoint}"
    token = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  }
}

# Cert-manager (Jetstack)
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.5"
  values = [ yamlencode({ installCRDs = true }) ]
}

# Optional Traefik
resource "helm_release" "traefik" {
  count      = var.enable_traefik ? 1 : 0
  name       = "traefik"
  namespace  = "traefik"
  create_namespace = true
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "26.0.0"
  values = [ yamlencode({
    additionalArguments = [
      "--entrypoints.web.http.redirections.entryPoint.to=websecure",
      "--entrypoints.web.http.redirections.entryPoint.scheme=https",
      "--certificatesresolvers.le.acme.tlschallenge=true",
      "--certificatesresolvers.le.acme.email=${var.acme_email}",
      "--certificatesresolvers.le.acme.storage=/data/acme.json"
    ],
    persistence = { enabled = true, size = "1Gi", accessMode = "ReadWriteOnce" },
    ports = { web = { expose = true, port = 80 }, websecure = { expose = true, port = 443 } }
  }) ]
}

# Gemx (local chart path)
resource "helm_release" "gemx" {
  name       = "gm"
  namespace  = "default"
  chart      = "${path.module}/../../../charts/gemx"
  values = [ yamlencode({
    ingress = {
      enabled   = true
      className = var.enable_traefik ? "traefik" : "gce"
      hosts     = [ { host = var.domain, paths = [ { path = "/", pathType = "Prefix" } ] } ]
      tls       = [ { secretName = "gemx-tls", hosts = [ var.domain ] } ]
    },
    oauth = {
      enabled = var.oauth_enabled
      googleClientId = var.google_client_id
      googleClientSecret = var.google_client_secret
      callbackUrl = "https://${var.domain}/auth/callback"
      allowedDomain = var.allowed_domain
    },
    persistence = { enabled = true, size = "5Gi", accessModes = ["ReadWriteOnce"] },
    gke = { neg = true }
  }) ]
  depends_on = [helm_release.cert_manager]
}

# DNS Zone (optional new)
resource "google_dns_managed_zone" "zone" {
  count = var.create_zone ? 1 : 0
  name        = replace(var.domain, ".", "-")
  dns_name    = "${var.domain}."
  description = "Managed by Terraform (gemx)"
}

# Output kubeconfig helper
resource "local_file" "kubeconfig" {
  content  = <<EOT
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${google_container_cluster.gke.master_auth.0.cluster_ca_certificate}
    server: https://${google_container_cluster.gke.endpoint}
  name: gke
contexts:
- context:
    cluster: gke
    user: gke
  name: gke
current-context: gke
users:
- name: gke
  user:
    token: ${data.google_client_config.default.access_token}
EOT
  filename = "${path.module}/kubeconfig"
}

output "cluster_name" { value = google_container_cluster.gke.name }
output "endpoint"     { value = google_container_cluster.gke.endpoint }
output "kubeconfig"   { value = local_file.kubeconfig.filename }
output "domain"       { value = var.domain }
