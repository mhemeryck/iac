terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.5.1"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
      version = ">= 1.26.0"
    }
  }
  required_version = ">= 0.13"
}

provider "digitalocean" {
  token = var.do_token
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "master" {
  name        = "master"
  image       = "centos-8"
  server_type = "cx21"
  ssh_keys    = [hcloud_ssh_key.kube_key.id]

  provisioner "remote-exec" {
    inline = [
      "yum install -y container-selinux selinux-policy-base",
      "rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = hcloud_server.master.ipv4_address
      private_key = file("./kube_key")
    }
  }
  firewall_ids = [hcloud_firewall.firewall.id]
}

resource "hcloud_firewall" "firewall" {
  name = "firewall"

  rule {
    direction = "in"
    protocol = "tcp"
    port = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol = "tcp"
    port = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol = "tcp"
    port = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

}

resource "hcloud_ssh_key" "kube_key" {
  name       = "kube_key"
  public_key = var.kube_key
}

resource "digitalocean_domain" "mhemeryck" {
  name = "mhemeryck.com"
}

resource "digitalocean_record" "landing" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "@"
  type   = "A"
  value  = hcloud_server.master.ipv4_address
  ttl    = 3600
}

resource "digitalocean_record" "ns1" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "@"
  type   = "NS"
  value  = "ns1.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "ns2" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "@"
  type   = "NS"
  value  = "ns2.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "ns3" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "@"
  type   = "NS"
  value  = "ns3.digitalocean.com."
  ttl    = 1800
}

resource "digitalocean_record" "cv" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "cv"
  type   = "A"
  value  = hcloud_server.master.ipv4_address
  ttl    = 3600
}

resource "digitalocean_record" "wekan" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "wekan"
  type   = "A"
  value  = hcloud_server.master.ipv4_address
  ttl    = 3600
}

resource "digitalocean_record" "blog" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "blog"
  type   = "CNAME"
  value  = "mhemeryck.github.io."
}

resource "digitalocean_record" "bitwarden" {
  domain = digitalocean_domain.mhemeryck.name
  name   = "bitwarden"
  type   = "A"
  value  = hcloud_server.master.ipv4_address
  ttl    = 3600
}
