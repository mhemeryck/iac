variable "host" {
  description = "Hostname served by Wekan."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace used by Wekan."
  type        = string
  default     = "wekan"
}

variable "wekan_image" {
  description = "Wekan container image."
  type        = string
  default     = "wekanteam/wekan:v7.94"
}

variable "mongodb_image" {
  description = "MongoDB container image."
  type        = string
  default     = "mongo:6.0.26-jammy"
}

variable "mongodb_storage" {
  description = "Storage requested for the MongoDB data volume."
  type        = string
  default     = "1Gi"
}

variable "cluster_issuer" {
  description = "cert-manager cluster issuer used for the ingress certificate."
  type        = string
  default     = "letsencrypt"
}

variable "ingress_class_name" {
  description = "Ingress class serving Wekan."
  type        = string
  default     = "traefik"
}

variable "tls_secret_name" {
  description = "Secret name receiving the ingress TLS certificate."
  type        = string
  default     = "wekan-mhemeryck-xyz-tls"
}
