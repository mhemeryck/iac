resource "kubernetes_namespace_v1" "hello" {
  metadata {
    name = "hello"
  }
}
