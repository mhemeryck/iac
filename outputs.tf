output "ip" {
	value = digitalocean_droplet.kube.ipv4_address
}

output "master_ip" {
	value = hcloud_server.master.ipv4_address
}
