terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "mhemeryck-terraform-state-109185239364"
    key          = "wekan/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

module "wekan" {
  source = "../../../wekan"

  host = "wekan.mhemeryck.xyz"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to manage the Wekan namespace."
  type        = string
}
