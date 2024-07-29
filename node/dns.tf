resource "hetznerdns_zone" "xyz" {
  name = "mhemeryck.xyz"
  ttl  = 3600
}

resource "hetznerdns_record" "xyz" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "@"
  value   = hcloud_server.k3s.ipv4_address
  type    = "A"
  ttl     = 3600
}

resource "hetznerdns_record" "wekan" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "wekan"
  value   = hcloud_server.k3s.ipv4_address
  type    = "A"
  ttl     = 300
}

resource "hetznerdns_record" "bitwarden" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "bitwarden"
  value   = hcloud_server.k3s.ipv4_address
  type    = "A"
  ttl     = 300
}
