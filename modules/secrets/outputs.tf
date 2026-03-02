output "mongodb_credentials_arn" {
  description = "ARN of MongoDB credentials secret"
  value       = aws_secretsmanager_secret.mongodb_credentials.arn
}

output "jwt_secret_arn" {
  description = "ARN of JWT secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "google_oauth_arn" {
  description = "ARN of Google OAuth secret"
  value       = aws_secretsmanager_secret.google_oauth.arn
}

output "grafana_admin_arn" {
  description = "ARN of Grafana admin secret"
  value       = aws_secretsmanager_secret.grafana_admin.arn
}

output "secrets_access_policy_arn" {
  description = "ARN of IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}

output "mongodb_username" {
  description = "MongoDB username"
  value       = var.mongodb_username
  sensitive   = true
}

output "mongodb_password" {
  description = "MongoDB password"
  value       = var.mongodb_password
  sensitive   = true
}

output "jwt_secret_value" {
  description = "Generated JWT secret"
  value       = random_password.jwt_secret.result
  sensitive   = true
}

output "grafana_admin_password" {
  description = "Generated Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
