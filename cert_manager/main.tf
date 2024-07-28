# load manifest from vendored cert-manager manifests
# https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml
data "kubectl_file_documents" "cert_manager" {
  content = file("${path.module}/vendor/cert-manager.yaml")
}

resource "kubectl_manifest" "cert_manager" {
  for_each  = data.kubectl_file_documents.cert_manager.manifests
  yaml_body = each.value
}
