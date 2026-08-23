variable "aws_region" {
  description = "AWS region containing the backup bucket."
  type        = string
  default     = "eu-central-1"
}

variable "billing_alert_email" {
  description = "Email address receiving Goalkeepr backup budget alerts."
  type        = string
}
