output "secret_name" {
  description = "Kubernetes Secret containing the backup upload credentials and bucket name."
  value       = kubernetes_secret_v1.backup.metadata[0].name
}
