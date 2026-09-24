module "backup_storage" {
  source = "../backup-storage"

  name               = "vaultwarden"
  namespace          = kubernetes_namespace_v1.bitwarden.metadata[0].name
  retention_days     = 90
  purpose            = "database-and-files-backups"
  upload_description = "Upload Vaultwarden backups without reading or deleting them."
}

moved {
  from = data.aws_caller_identity.current
  to   = module.backup_storage.data.aws_caller_identity.current
}

moved {
  from = module.backup_bucket
  to   = module.backup_storage.module.bucket
}

moved {
  from = module.backup_upload_policy
  to   = module.backup_storage.module.upload_policy
}

moved {
  from = module.backup_upload_user
  to   = module.backup_storage.module.upload_user
}

moved {
  from = kubernetes_secret_v1.backup
  to   = module.backup_storage.kubernetes_secret_v1.backup
}

resource "kubernetes_cron_job_v1" "backup" {
  metadata {
    name      = "vaultwarden-backup"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    schedule                      = "0 3 * * *"
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

            volume {
              name = "vault"

              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.vault.metadata[0].name
              }
            }

            init_container {
              name  = "dump"
              image = "postgres:16.3-alpine3.20"
              command = ["/bin/sh", "-ceu", <<-EOT
                pg_dump \
                  --format=custom \
                  --no-owner \
                  --no-privileges \
                  --file=/backup/postgres.dump
                pg_restore --list /backup/postgres.dump >/dev/null
              EOT
              ]

              env {
                name  = "PGDATABASE"
                value = "postgres"
              }

              env {
                name  = "PGHOST"
                value = kubernetes_service_v1.postgres.metadata[0].name
              }

              env {
                name = "PGPASSWORD"

                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.postgres.metadata[0].name
                    key  = "password"
                  }
                }
              }

              env {
                name  = "PGUSER"
                value = "postgres"
              }

              volume_mount {
                name       = "backup"
                mount_path = "/backup"
              }
            }

            init_container {
              name  = "archive"
              image = "alpine:3.23"
              command = ["/bin/sh", "-ceu", <<-EOT
                tar -czf /backup/data.tar.gz -C /data .
                tar -tzf /backup/data.tar.gz >/dev/null
                tar -czf /backup/vaultwarden.tar.gz \
                  -C /backup postgres.dump data.tar.gz
                tar -tzf /backup/vaultwarden.tar.gz >/dev/null
              EOT
              ]

              volume_mount {
                name       = "backup"
                mount_path = "/backup"
              }

              volume_mount {
                name       = "vault"
                mount_path = "/data"
                read_only  = true
              }
            }

            container {
              name  = "upload"
              image = "amazon/aws-cli:2.35.11"
              command = ["/bin/sh", "-ceu", <<-EOT
                timestamp="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
                aws s3 cp \
                  /backup/vaultwarden.tar.gz \
                  "s3://$${S3_BUCKET}/vaultwarden/$${timestamp}.tar.gz" \
                  --only-show-errors
              EOT
              ]

              env {
                name = "AWS_ACCESS_KEY_ID"

                value_from {
                  secret_key_ref {
                    name = module.backup_storage.secret_name
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
                    name = module.backup_storage.secret_name
                    key  = "secret_access_key"
                  }
                }
              }

              env {
                name = "S3_BUCKET"

                value_from {
                  secret_key_ref {
                    name = module.backup_storage.secret_name
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
