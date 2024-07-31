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
  ttl     = 3600
}

resource "hetznerdns_record" "bitwarden" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "bitwarden"
  value   = hcloud_server.k3s.ipv4_address
  type    = "A"
  ttl     = 3600
}

resource "hetznerdns_record" "blog" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "blog"
  value   = "mhemeryck.github.io."
  type    = "CNAME"
  ttl     = 3600
}

resource "hetznerdns_zone" "com" {
  name = "mhemeryck.com"
  ttl  = 3600
}

resource "hetznerdns_record" "com" {
  zone_id = hetznerdns_zone.com.id
  name    = "mhemeryck.com"
  value   = "mhemeryck.xyz."
  type    = "CNAME"
  ttl     = 3600
}
