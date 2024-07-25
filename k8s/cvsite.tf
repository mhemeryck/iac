resource "kubernetes_namespace_v1" "cvsite" {
  metadata {
    name = "cvsite"
  }
}

resource "kubernetes_service_v1" "cvsite" {
  metadata {
    name      = "cvsite"
    namespace = kubernetes_namespace_v1.cvsite.metadata[0].name
  }

  spec {
    selector = {
      app = "cvsite"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment_v1" "cvsite" {
  metadata {
    name      = "cvsite"
    namespace = kubernetes_namespace_v1.cvsite.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "cvsite"
      }
    }
    template {
      metadata {
        labels = {
          app = "cvsite"
        }
      }
      spec {
        container {
          image = "mhemeryck/cvsite:latest"
          name  = "cvsite"
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "cvsite" {
  depends_on = [kubernetes_manifest.cluster_issuer]
  metadata {
    name      = "cvsite"
    namespace = kubernetes_namespace_v1.cvsite.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"        = "traefik"
      "cert-manager.io/cluster-issuer"     = "letsencrypt"
      "ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }
  spec {
    tls {
      hosts = [
        "cv.mhemeryck.xyz",
        "mhemeryck.xyz",
      ]
      secret_name = "cv-mhemeryck-xyz-tls"
    }
    rule {
      host = "mhemeryck.xyz"
      http {
        path {
          backend {
            service {
              name = kubernetes_namespace_v1.cvsite.metadata[0].name
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
