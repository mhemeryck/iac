output "private_key" {
  value     = tls_private_key.provisioning.private_key_openssh
  sensitive = true
}

output "ip" {
  value = hcloud_server.k3s.ipv4_address
}

output "kubeconfig" {
  value     = data.external.kubeconfig.result["kubeconfig"]
  sensitive = true
}
