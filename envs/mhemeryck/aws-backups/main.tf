terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "goalkeepr_backups" {
  source = "../../../aws-backups"
}

variable "aws_region" {
  description = "AWS region containing the Goalkeepr backup bucket."
  type        = string
  default     = "eu-central-1"
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
