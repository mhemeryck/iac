provider "kubernetes" {
  host = "https://${var.node_ip}:6443"

  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}
