data "kubectl_file_documents" "cert_manager" {
  content = file("${path.module}/vendor/cert-manager.yaml")
}

resource "kubectl_manifest" "cert_manager" {
  for_each  = data.kubectl_file_documents.cert_manager.manifests
  yaml_body = each.value
}
