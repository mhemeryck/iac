resource "kubernetes_namespace_v1" "bitwarden" {
  metadata {
    name = "bitwarden"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_secret_v1" "vault" {
  wait_for_service_account_token = false

  metadata {
    name      = "vault-secrets"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  type = "Opaque"

  lifecycle {
    # Import existing credentials without replacing or recording them in HCL.
    ignore_changes  = [data, binary_data]
    prevent_destroy = true
  }
}

resource "kubernetes_secret_v1" "postgres" {
  wait_for_service_account_token = false

  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  type = "Opaque"

  lifecycle {
    ignore_changes  = [data, binary_data]
    prevent_destroy = true
  }
}

resource "kubernetes_persistent_volume_claim_v1" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "256Mi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_persistent_volume_claim_v1" "postgres" {
  metadata {
    name      = "postgres-pgdata"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_deployment_v1" "bitwarden" {
  wait_for_rollout = false

  depends_on = [kubernetes_secret_v1.vault, kubernetes_secret_v1.postgres]

  metadata {
    name      = "bitwarden"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "bitwarden"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = {
          app = "bitwarden"
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        volume {
          name = "vault"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.vault.metadata[0].name
          }
        }

        container {
          name  = "bitwarden"
          image = "vaultwarden/server:1.37.2-alpine"

          volume_mount {
            name       = "vault"
            mount_path = "/data"
          }

          env {
            name = "ADMIN_TOKEN"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.vault.metadata[0].name
                key  = "admin_token"
              }
            }
          }

          env {
            name = "YUBICO_CLIENT_ID"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.vault.metadata[0].name
                key  = "yubico_client_id"
              }
            }
          }

          env {
            name = "YUBICO_SECRET_KEY"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.vault.metadata[0].name
                key  = "yubico_secret_key"
              }
            }
          }

          env {
            name = "DATABASE_URL"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "database_url"
              }
            }
          }

          env {
            name  = "DOMAIN"
            value = "https://bitwarden.mhemeryck.xyz"
          }

          env {
            name  = "SIGNUPS_ALLOWED"
            value = "false"
          }

          env {
            name  = "INVITATIONS_ALLOWED"
            value = "false"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      wait_for_rollout,
      spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"],
    ]
  }
}

resource "kubernetes_service_v1" "bitwarden" {
  wait_for_load_balancer = false

  metadata {
    name      = "bitwarden"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "bitwarden"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  wait_for_rollout = false

  depends_on = [kubernetes_secret_v1.postgres]

  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    replicas     = 1
    service_name = kubernetes_service_v1.postgres.metadata[0].name

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        volume {
          name = "pgdata"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.postgres.metadata[0].name
          }
        }

        container {
          name  = "postgres"
          image = "postgres:16.3-alpine3.20"

          resources {
            limits = {
              memory = "512Mi"
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql/data"
          }

          env {
            name = "POSTGRES_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres.metadata[0].name
                key  = "password"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [wait_for_rollout]
  }
}

resource "kubernetes_service_v1" "postgres" {
  wait_for_load_balancer = false

  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_ingress_v1" "bitwarden" {
  metadata {
    name      = "bitwarden"
    namespace = kubernetes_namespace_v1.bitwarden.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = "bitwarden.mhemeryck.xyz"

      http {
        path {
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.bitwarden.metadata[0].name

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["bitwarden.mhemeryck.xyz"]
      secret_name = "bitwarden-mhemeryck-xyz-tls"
    }
  }
}
