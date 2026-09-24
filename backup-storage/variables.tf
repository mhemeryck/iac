variable "name" {
  description = "Application name used for the bucket, upload identity, prefix, and Kubernetes Secret."
  type        = string
}

variable "namespace" {
  description = "Namespace for the backup upload Secret."
  type        = string
}

variable "retention_days" {
  description = "Object Lock retention and backup expiration in days."
  type        = number

  validation {
    condition     = var.retention_days >= 1 && floor(var.retention_days) == var.retention_days
    error_message = "Backup retention must be a positive number of whole days."
  }
}

variable "purpose" {
  description = "Purpose tag for the backup bucket."
  type        = string
}

variable "upload_description" {
  description = "Description of the upload-only IAM policy."
  type        = string
}
