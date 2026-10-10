locals {
  namespace       = kubernetes_namespace_v1.frp.metadata[0].name
  tls_secret_name = "homeassistant-remote-tls"
  labels          = { app = "frps" }
}

resource "kubernetes_namespace_v1" "frp" {
  metadata {
    name = "frp"
  }
}

resource "random_password" "token" {
  length  = 48
  special = false
}

resource "kubernetes_secret_v1" "auth" {
  metadata {
    name      = "frp-auth"
    namespace = local.namespace
  }

  data = { token = random_password.token.result }
}

resource "kubernetes_config_map_v1" "server" {
  metadata {
    name      = "frps-config"
    namespace = local.namespace
  }

  data = {
    "frps.toml"   = file("${path.module}/frps.toml")
    "run-frps.sh" = file("${path.module}/run-frps.sh")
  }
}

resource "kubernetes_deployment_v1" "server" {
  # The ingress provisions the TLS Secret asynchronously through cert-manager.
  wait_for_rollout = false

  metadata {
    name      = "frps"
    namespace = local.namespace
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
        annotations = {
          "checksum/config" = sha256(jsonencode(kubernetes_config_map_v1.server.data))
        }
      }

      spec {
        automount_service_account_token  = false
        termination_grace_period_seconds = 20

        security_context {
          run_as_non_root = true
          run_as_user     = 65532
          run_as_group    = 65532
        }

        container {
          name    = "frps"
          image   = "ghcr.io/fatedier/frps:v0.71.0"
          command = ["/bin/sh", "/etc/frp/config/run-frps.sh"]

          port {
            name           = "tunnel"
            container_port = 7000
          }

          port {
            name           = "homeassistant"
            container_port = 8080
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = { cpu = "25m", memory = "32Mi" }
            limits   = { memory = "128Mi" }
          }

          readiness_probe {
            tcp_socket {
              port = "tunnel"
            }
            period_seconds = 5
          }

          liveness_probe {
            tcp_socket {
              port = "tunnel"
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/frp/config"
            read_only  = true
          }

          volume_mount {
            name       = "auth"
            mount_path = "/etc/frp/auth"
            read_only  = true
          }

          volume_mount {
            name       = "tls"
            mount_path = "/etc/frp/tls"
            read_only  = true
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.server.metadata[0].name
          }
        }

        volume {
          name = "auth"
          secret {
            secret_name = kubernetes_secret_v1.auth.metadata[0].name
          }
        }

        volume {
          name = "tls"
          secret {
            secret_name = local.tls_secret_name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "tunnel" {
  metadata {
    name      = "frp-tunnel"
    namespace = local.namespace
  }

  spec {
    type     = "NodePort"
    selector = local.labels

    port {
      name        = "tunnel"
      port        = 7000
      target_port = "tunnel"
      node_port   = var.tunnel_node_port
    }
  }
}

resource "kubernetes_service_v1" "homeassistant" {
  metadata {
    name      = "homeassistant-tunnel"
    namespace = local.namespace
  }

  spec {
    selector = local.labels

    port {
      name        = "http"
      port        = 80
      target_port = "homeassistant"
    }
  }
}

resource "kubernetes_ingress_v1" "homeassistant" {
  metadata {
    name      = "homeassistant"
    namespace = local.namespace
    annotations = {
      "cert-manager.io/cluster-issuer"                   = "letsencrypt"
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"         = "true"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.hostname]
      secret_name = local.tls_secret_name
    }

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.homeassistant.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
