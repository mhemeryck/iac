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
  metadata {
    name      = "cvsite"
    namespace = kubernetes_namespace_v1.cvsite.metadata[0].name
  }
  spec {
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
