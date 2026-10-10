output "frp_token" {
  description = "Copy this generated token to the home client's pass entry."
  value       = random_password.token.result
  sensitive   = true
}

output "homeassistant_url" {
  value = "https://${var.hostname}"
}
