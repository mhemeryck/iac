locals {
  acme_servers = {
    letsencrypt         = "https://acme-v02.api.letsencrypt.org/directory"
    letsencrypt-staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }
}

resource "kubernetes_manifest" "letsencrypt" {
  for_each = local.acme_servers

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = each.key
    }

    spec = {
      acme = {
        server = each.value
        email  = var.email

        privateKeySecretRef = {
          name = each.key
        }

        solvers = [{
          selector = {}
          http01 = {
            ingress = {
              ingressClassName = "traefik"
            }
          }
        }]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
