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
    key          = "platform/github-actions/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "github_actions" {
  source = "../../../github-actions"
}

moved {
  from = aws_iam_openid_connect_provider.github_actions
  to   = module.github_actions.aws_iam_openid_connect_provider.github_actions
}

moved {
  from = aws_iam_role.github_actions
  to   = module.github_actions.aws_iam_role.github_actions
}

moved {
  from = aws_iam_role_policy_attachment.github_actions_administrator
  to   = module.github_actions.aws_iam_role_policy_attachment.github_actions_administrator
}

output "role_arn" {
  description = "ARN GitHub Actions workflows assume through OpenID Connect."
  value       = module.github_actions.role_arn
}
