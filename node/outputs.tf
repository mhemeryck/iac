output "private_key" {
  sensitive = true
  value     = tls_private_key.provisioning.private_key_openssh
}

output "ip" {
  value = hcloud_server.k3s.ipv4_address
}
