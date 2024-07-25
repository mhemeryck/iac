variable "client_certificate" {
  description = "k8s client certificate"
}

variable "client_key" {
  description = "k8s client key"
}

variable "cluster_ca_certificate" {
  description = "k8s cluster CA certificate"
}

variable "node_ip" {
  description = "IP of the provisioned node"
}

variable "cert_manager_email" {
  description = "ACME cert-manager e-mail address"
  default     = "martijn.hemeryck@gmail.com"
}
