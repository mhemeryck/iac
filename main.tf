provider "digitalocean" {
	token = var.do_token
}

resource "digitalocean_droplet" "kube" {
	image = "debian-10-x64"
	name = "kube"
	region = "ams3"
	size = "s-1vcpu-1gb"
	ssh_keys = [digitalocean_ssh_key.kube_key.fingerprint]
}

resource "digitalocean_ssh_key" "kube_key" {
	name = "kube_key"
	public_key = var.kube_key
}

resource "digitalocean_firewall" "web" {
	name = "ssh-web-kube"

	droplet_ids = [digitalocean_droplet.kube.id]

	inbound_rule {
		protocol = "tcp"
		port_range = "22"
		source_addresses = ["0.0.0.0/0", "::/0"]
	}

	inbound_rule {
		protocol = "tcp"
		port_range = "80"
		source_addresses = ["0.0.0.0/0", "::/0"]
	}

	inbound_rule {
		protocol = "tcp"
		port_range = "443"
		source_addresses = ["0.0.0.0/0", "::/0"]
	}

	inbound_rule {
		protocol = "tcp"
		port_range = "6443"
		source_addresses = ["0.0.0.0/0", "::/0"]
	}

	outbound_rule {
		protocol = "tcp"
		port_range = "1-1024"
		destination_addresses = ["0.0.0.0/0", "::/0"]
	}

	outbound_rule {
		protocol = "udp"
		port_range = "1-1024"
		destination_addresses = ["0.0.0.0/0", "::/0"]
	}

	outbound_rule {
		protocol = "icmp"
		destination_addresses = ["0.0.0.0/0", "::/0"]
	}
}
