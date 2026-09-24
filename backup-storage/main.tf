data "aws_caller_identity" "current" {}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = "${var.name}-backups-${data.aws_caller_identity.current.account_id}"

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
        days = var.retention_days
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "expire-backups-after-retention"
      enabled = true

      expiration = {
        days = var.retention_days
      }

      noncurrent_version_expiration = {
        days = 1
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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true

  tags = {
    Application = var.name
    Purpose     = var.purpose
  }
}

module "upload_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${var.name}-backup-upload"
  description = var.upload_description
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
        Resource = "${module.bucket.s3_bucket_arn}/${var.name}/*"
      },
    ]
  })
}

module "upload_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 6.8"

  name                 = "${var.name}-backup"
  create_access_key    = true
  create_login_profile = false
  force_destroy        = false
  policies = {
    upload = module.upload_policy.arn
  }
}

resource "kubernetes_secret_v1" "backup" {
  wait_for_service_account_token = false

  metadata {
    name      = "${var.name}-backup"
    namespace = var.namespace
  }

  data = {
    access_key_id     = module.upload_user.access_key_id
    bucket            = module.bucket.s3_bucket_id
    secret_access_key = module.upload_user.access_key_secret
  }

  type = "Opaque"
}
