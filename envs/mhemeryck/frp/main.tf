terraform {
  required_version = "~> 1.15"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
  }

  backend "s3" {
    bucket       = "mhemeryck-terraform-state-109185239364"
    key          = "frp/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

module "frp" {
  source = "../../../frp"
}

variable "kubeconfig_path" {
  description = "Path to the remote cluster kubeconfig."
  type        = string
}

output "frp_token" {
  value     = module.frp.frp_token
  sensitive = true
}

output "homeassistant_url" {
  value = module.frp.homeassistant_url
}
