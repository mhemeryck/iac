# load manifest from vendored cert-manager manifests
# https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml
data "kubectl_file_documents" "cert_manager" {
  content = file("${path.module}/vendor/cert-manager.yaml")
}

resource "kubectl_manifest" "cert_manager" {
  for_each  = data.kubectl_file_documents.cert_manager.manifests
  yaml_body = each.value
}

# staging cluster issuer
resource "kubernetes_manifest" "cluster_issuer_staging" {
  depends_on = [kubectl_manifest.cert_manager]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "traefik"
              }
            }
          }
        ]
      }
    }
  }
}

# production cluster issuer
resource "kubernetes_manifest" "cluster_issuer" {
  depends_on = [kubectl_manifest.cert_manager]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "traefik"
              }
            }
          }
        ]
      }
    }
  }
}
