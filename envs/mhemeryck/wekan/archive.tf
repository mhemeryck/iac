// Keep the final backup under its existing 90-day retention after retiring Wekan.
moved {
  from = module.wekan.module.backup_storage.module.bucket
  to   = module.wekan_backup_bucket
}

module "wekan_backup_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = "wekan-backups-109185239364"

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
    Application = "wekan"
    Purpose     = "database-backups"
  }
}
