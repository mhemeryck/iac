resource "hcloud_zone" "xyz" {
  name = "mhemeryck.xyz"
  mode = "primary"

  ttl = 3600

  delete_protection = false
}

resource "hcloud_zone_rrset" "xyz" {
  zone    = hcloud_zone.xyz.name
  name    = "@"
  type    = "A"
  records = [{ value = hcloud_server.k3s.ipv4_address }]
}

resource "hcloud_zone_rrset" "bitwarden" {
  zone    = hcloud_zone.xyz.name
  name    = "bitwarden"
  type    = "A"
  records = [{ value = hcloud_server.k3s.ipv4_address }]
}

resource "hcloud_zone_rrset" "wekan" {
  zone    = hcloud_zone.xyz.name
  name    = "wekan"
  type    = "A"
  records = [{ value = hcloud_server.k3s.ipv4_address }]
}

resource "hcloud_zone_rrset" "facturette" {
  zone    = hcloud_zone.xyz.name
  name    = "facturette"
  type    = "A"
  records = [{ value = hcloud_server.k3s.ipv4_address }]
}

resource "hcloud_zone_rrset" "blog" {
  zone    = hcloud_zone.xyz.name
  name    = "blog"
  type    = "CNAME"
  records = [{ value = "mhemeryck.github.io." }]
}
