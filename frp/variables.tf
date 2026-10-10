variable "hostname" {
  description = "Public hostname for Home Assistant and the tunnel listener."
  type        = string
  default     = "hass.mhemeryck.xyz"
}

variable "tunnel_node_port" {
  description = "Public tunnel NodePort; keep this aligned with the node firewall and home client."
  type        = number
  default     = 30700
}
