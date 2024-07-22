module "node" {
  source = "../../../node"

  hcloud_token = var.hcloud_token
}

variable "hcloud_token" {
  description = "hetzner cloud API token"
  sensitive   = true
}

locals {
  kubeconfig             = yamldecode(module.node.kubeconfig)
  client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
}

output "ip" {
  description = "hetzner instance ip"
  value       = module.node.ip
}

output "private_key" {
  sensitive = true
  value     = module.node.private_key
}

output "kubeconfig" {
  sensitive = true
  value     = local.kubeconfig
}

output "kubecerts" {
  sensitive   = true
  description = "parsed output of kubeconfig to be used in kubernetes provider"
  value = {
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host = "https://${module.node.ip}:6443"

  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate
}
