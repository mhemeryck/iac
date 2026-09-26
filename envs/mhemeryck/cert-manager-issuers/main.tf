terraform {
  required_version = "~> 1.15"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "mhemeryck-terraform-state-109185239364"
    key          = "platform/cert-manager-issuers/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

module "cert_manager_issuers" {
  source = "../../../cert-manager-issuers"

  email = var.email
}

variable "email" {
  description = "Email address used for Let's Encrypt ACME accounts."
  type        = string
  default     = "martijn.hemeryck@gmail.com"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to manage cert-manager ClusterIssuers."
  type        = string
}
