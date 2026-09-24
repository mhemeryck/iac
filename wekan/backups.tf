data "aws_caller_identity" "current" {}

module "backup_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = "wekan-backups-${data.aws_caller_identity.current.account_id}"

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

module "backup_upload_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "wekan-backup-upload"
  description = "Upload Wekan MongoDB backups without reading or deleting them."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
        ]
        Resource = module.backup_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
        ]
        Resource = "${module.backup_bucket.s3_bucket_arn}/wekan/*"
      },
    ]
  })
}

module "backup_upload_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 6.8"

  name                 = "wekan-backup"
  create_access_key    = true
  create_login_profile = false
  force_destroy        = false
  policies = {
    upload = module.backup_upload_policy.arn
  }
}

resource "kubernetes_secret_v1" "backup" {
  wait_for_service_account_token = false

  metadata {
    name      = "wekan-backup"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  data = {
    access_key_id     = module.backup_upload_user.access_key_id
    bucket            = module.backup_bucket.s3_bucket_id
    secret_access_key = module.backup_upload_user.access_key_secret
  }

  type = "Opaque"
}

resource "kubernetes_cron_job_v1" "mongodb_backup" {
  metadata {
    name      = "mongodb-backup"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    schedule                      = "0 2 * * *"
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 7
    successful_jobs_history_limit = 7
    starting_deadline_seconds     = 3600

    job_template {
      metadata {
        annotations = {}
        labels      = {}
      }

      spec {
        backoff_limit = 2
        parallelism   = 1

        template {
          metadata {
            annotations = {}
            labels      = {}
          }

          spec {
            automount_service_account_token = false
            enable_service_links            = false
            restart_policy                  = "Never"

            volume {
              name = "backup"

              empty_dir {}
            }

            init_container {
              name  = "dump"
              image = var.mongodb_image
              command = ["/bin/sh", "-ceu", <<-EOT
                mongodump \
                  --host mongodb \
                  --db wekan \
                  --archive=/backup/wekan.archive.gz \
                  --gzip
              EOT
              ]

              volume_mount {
                name       = "backup"
                mount_path = "/backup"
              }
            }

            container {
              name  = "upload"
              image = "amazon/aws-cli:2.35.11"
              command = ["/bin/sh", "-ceu", <<-EOT
                timestamp="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
                aws s3 cp \
                  /backup/wekan.archive.gz \
                  "s3://$${S3_BUCKET}/wekan/$${timestamp}.archive.gz" \
                  --only-show-errors
              EOT
              ]

              env {
                name = "AWS_ACCESS_KEY_ID"

                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.backup.metadata[0].name
                    key  = "access_key_id"
                  }
                }
              }

              env {
                name  = "AWS_DEFAULT_REGION"
                value = "eu-central-1"
              }

              env {
                name = "AWS_SECRET_ACCESS_KEY"

                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.backup.metadata[0].name
                    key  = "secret_access_key"
                  }
                }
              }

              env {
                name = "S3_BUCKET"

                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.backup.metadata[0].name
                    key  = "bucket"
                  }
                }
              }

              volume_mount {
                name       = "backup"
                mount_path = "/backup"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    # The provider renders Kubernetes' omitted completion default as zero.
    ignore_changes = [spec[0].job_template[0].spec[0].completions]
  }
}
