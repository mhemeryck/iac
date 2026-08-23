output "role_arn" {
  description = "ARN GitHub Actions workflows assume through OpenID Connect."
  value       = aws_iam_role.github_actions.arn
}
