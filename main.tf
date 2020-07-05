provider "digitalocean" {
	token = var.do_token
}

resource "digitalocean_droplet" "kube" {
	image = "centos-8-x64"
	name = "kube"
	region = "ams3"
	size = "s-1vcpu-3gb"
	ssh_keys = [digitalocean_ssh_key.kube_key.fingerprint]

	provisioner "remote-exec" {
		inline = [
			"yum install -y container-selinux selinux-policy-base",
			"rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm",
		]

		connection {
			type = "ssh"
			user = "root"
			host = digitalocean_droplet.kube.ipv4_address
			private_key = file("./kube_key")
		}
	}
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

resource "digitalocean_domain" "mhemeryck" {
	name = "mhemeryck.com"
}

#resource "digitalocean_record" "landing" {
#	domain = digitalocean_domain.mhemeryck.name
#	name = "@"
#	type = "A"
#	value = digitalocean_droplet.kube.ipv4_address
#	ttl = 3600
#}
#
resource "digitalocean_record" "ns1" {
	domain = digitalocean_domain.mhemeryck.name
	name = "@"
	type = "NS"
	value = "ns1.digitalocean.com."
	ttl = 1800
}

resource "digitalocean_record" "ns2" {
	domain = digitalocean_domain.mhemeryck.name
	name = "@"
	type = "NS"
	value = "ns2.digitalocean.com."
	ttl = 1800
}

resource "digitalocean_record" "ns3" {
	domain = digitalocean_domain.mhemeryck.name
	name = "@"
	type = "NS"
	value = "ns3.digitalocean.com."
	ttl = 1800
}

resource "digitalocean_record" "cv" {
	domain = digitalocean_domain.mhemeryck.name
	name = "cv"
	type = "A"
	value = digitalocean_droplet.kube.ipv4_address
	ttl = 3600
}

resource "digitalocean_record" "kanban" {
	domain = digitalocean_domain.mhemeryck.name
	name = "kanban"
	type = "A"
	value = digitalocean_droplet.kube.ipv4_address
	ttl = 3600
}
