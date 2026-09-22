resource "kubernetes_namespace_v1" "wekan" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment_v1" "wekan" {
  wait_for_rollout = false

  metadata {
    name      = "wekan"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wekan"
      }
    }

    template {
      metadata {
        labels = {
          app = "wekan"
        }
      }

      spec {
        container {
          name  = "wekan"
          image = var.wekan_image

          env {
            name  = "MONGO_URL"
            value = "mongodb://${kubernetes_service_v1.mongodb.metadata[0].name}/wekan"
          }

          env {
            name  = "ROOT_URL"
            value = "https://${var.host}"
          }

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "wekan" {
  wait_for_load_balancer = false

  metadata {
    name      = "wekan"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    selector = {
      app = "wekan"
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.mongodb_storage
      }
    }
  }
}

resource "kubernetes_stateful_set_v1" "mongodb" {
  wait_for_rollout = false

  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    replicas     = 1
    service_name = kubernetes_service_v1.mongodb.metadata[0].name

    selector {
      match_labels = {
        app = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }

      spec {
        container {
          name  = "mongo"
          image = var.mongodb_image

          volume_mount {
            name       = "mongodb"
            mount_path = "/data/db"
          }
        }

        volume {
          name = "mongodb"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.mongodb.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "mongodb" {
  wait_for_load_balancer = false

  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name
  }

  spec {
    selector = {
      app = "mongodb"
    }

    port {
      port = 27017
    }
  }
}

resource "kubernetes_ingress_v1" "wekan" {
  metadata {
    name      = "wekan"
    namespace = kubernetes_namespace_v1.wekan.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer"     = var.cluster_issuer
      "ingress.kubernetes.io/ssl-redirect" = "true"
      "kubernetes.io/ingress.className"    = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.host

      http {
        path {
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = kubernetes_service_v1.wekan.metadata[0].name

              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }
  }
}
