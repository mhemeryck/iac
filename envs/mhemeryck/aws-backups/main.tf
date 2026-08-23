terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }
  }

  backend "s3" {
    bucket       = "mhemeryck-terraform-state-109185239364"
    key          = "goalkeepr/backups/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "goalkeepr_backups" {
  source              = "../../../aws-backups"
  billing_alert_email = var.billing_alert_email
}

variable "aws_region" {
  description = "AWS region containing the Goalkeepr backup bucket."
  type        = string
  default     = "eu-central-1"
}

variable "billing_alert_email" {
  description = "Email address receiving Goalkeepr backup budget alerts."
  type        = string
}

output "bucket_name" {
  value = module.goalkeepr_backups.bucket_name
}

output "access_key_id" {
  value     = module.goalkeepr_backups.access_key_id
  sensitive = true
}

output "secret_access_key" {
  value     = module.goalkeepr_backups.secret_access_key
  sensitive = true
}
