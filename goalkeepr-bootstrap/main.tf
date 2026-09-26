resource "kubernetes_namespace_v1" "goalkeepr" {
  metadata {
    name = "goalkeepr"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_service_account_v1" "terraform" {
  metadata {
    name      = "goalkeepr-terraform"
    namespace = kubernetes_namespace_v1.goalkeepr.metadata[0].name
  }

  lifecycle {
    # The API leaves this unset, but the provider plans its default as true after import.
    ignore_changes = [automount_service_account_token]
  }
}

resource "kubernetes_role_v1" "terraform" {
  metadata {
    name      = "goalkeepr-terraform"
    namespace = kubernetes_namespace_v1.goalkeepr.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims", "secrets", "services"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "terraform" {
  metadata {
    name      = "goalkeepr-terraform"
    namespace = kubernetes_namespace_v1.goalkeepr.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.terraform.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.terraform.metadata[0].name
    namespace = kubernetes_namespace_v1.goalkeepr.metadata[0].name
  }
}

resource "kubernetes_secret_v1" "terraform_token" {
  wait_for_service_account_token = false

  metadata {
    name      = "goalkeepr-terraform-token"
    namespace = kubernetes_namespace_v1.goalkeepr.metadata[0].name

    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.terraform.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account_v1.terraform]

  lifecycle {
    # The provider omits this controller-managed annotation when reading the Secret.
    ignore_changes = [metadata[0].annotations["kubernetes.io/service-account.name"], wait_for_service_account_token]
  }
}
