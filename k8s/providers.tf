provider "kubernetes" {
  host = "http://${variable.node_ip}"

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
}
