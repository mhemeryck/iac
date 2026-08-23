output "bucket_name" {
  description = "S3 bucket storing Terraform state."
  value       = module.bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket storing Terraform state."
  value       = module.bucket.s3_bucket_arn
}
