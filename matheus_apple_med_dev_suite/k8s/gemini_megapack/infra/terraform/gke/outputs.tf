output "gke_cluster" {
  value = {
    name     = google_container_cluster.gke.name
    endpoint = google_container_cluster.gke.endpoint
  }
}
