module "node" {
  source = "../../../node"

  hcloud_token = var.hcloud_token
}

variable "hcloud_token" {
  description = "hetzner cloud API token"
  sensitive   = true
}

output "ip" {
  description = "hetzner instance ip"
  value       = module.node.ip
}
