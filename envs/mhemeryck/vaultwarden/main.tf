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
    key          = "vaultwarden/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

module "vaultwarden" {
  source = "../../../vaultwarden"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to manage the Vaultwarden namespace."
  type        = string
}
