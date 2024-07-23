resource "hetznerdns_zone" "xyz" {
  name = "mhemeryck.xyz"
  ttl  = 300
}

resource "hetznerdns_record" "xyz" {
  zone_id = hetznerdns_zone.xyz.id
  name    = "@"
  value   = hcloud_server.k3s.ipv4_address
  type    = "A"
  ttl     = 300
}
