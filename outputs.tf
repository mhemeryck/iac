output "master_ip" {
  value = hcloud_server.master.ipv4_address
}

output "armsmaster_ip" {
  value = hcloud_server.armsmaster.ipv4_address
}
