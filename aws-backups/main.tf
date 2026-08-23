data "aws_caller_identity" "current" {}

locals {
  bucket_name = "goalkeepr-backups-${data.aws_caller_identity.current.account_id}"
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = local.bucket_name

  force_destroy            = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 90
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "expire-backups-after-retention"
      enabled = true

      expiration = {
        days = 90
      }

      noncurrent_version_expiration = {
        days = 90
      }
    },
  ]

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = true

  tags = {
    Application = "goalkeepr"
    Purpose     = "database-backups"
  }
}

module "upload_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "goalkeepr-backup-upload"
  description = "Upload Goalkeepr PostgreSQL backups without reading or deleting them."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
        ]
        Resource = module.bucket.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
        ]
        Resource = "${module.bucket.s3_bucket_arn}/goalkeepr/*"
      },
    ]
  })
}

module "upload_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 6.8"

  name                 = "goalkeepr-backup"
  create_access_key    = true
  create_login_profile = false
  force_destroy        = false
  policies = {
    upload = module.upload_policy.arn
  }
}

resource "aws_budgets_budget" "monthly_cost" {
  name         = "goalkeepr-backups"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [var.billing_alert_email]
  }
}
