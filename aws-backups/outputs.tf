output "bucket_name" {
  description = "S3 bucket receiving Goalkeepr database backups."
  value       = module.bucket.s3_bucket_id
}

output "access_key_id" {
  description = "Access key ID for the Goalkeepr backup Kubernetes secret."
  value       = module.upload_user.access_key_id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for the Goalkeepr backup Kubernetes secret."
  value       = module.upload_user.access_key_secret
  sensitive   = true
}
