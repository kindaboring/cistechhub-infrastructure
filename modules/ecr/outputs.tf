output "web_repository_url" {
  description = "URL of the web ECR repository"
  value       = aws_ecr_repository.web.repository_url
}

output "auth_repository_url" {
  description = "URL of the auth ECR repository"
  value       = aws_ecr_repository.auth.repository_url
}

output "web_repository_arn" {
  description = "ARN of the web ECR repository"
  value       = aws_ecr_repository.web.arn
}

output "auth_repository_arn" {
  description = "ARN of the auth ECR repository"
  value       = aws_ecr_repository.auth.arn
}
