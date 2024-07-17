provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "k3s" {
  name        = "k3s"
  image       = "ubuntu-22.04"
  server_type = "cx22"
  ssh_keys    = [hcloud_ssh_key.k3s.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = hcloud_server.k3s.ipv4_address
      private_key = tls_private_key.provisioning.private_key_openssh
    }
  }

  firewall_ids = [hcloud_firewall.k3s.id]
}

resource "tls_private_key" "provisioning" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "k3s" {
  name       = "k3s"
  public_key = tls_private_key.provisioning.public_key_openssh
}

resource "hcloud_firewall" "k3s" {
  name = "k3s"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}
