output "instance_id" {
  description = "ID of the cistechhub server"
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "Public IP address (Elastic IP) - Use this to access your application"
  value       = aws_eip.app_server.public_ip
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.key_name != "" ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.app_server.public_ip}" : "Use AWS Systems Manager Session Manager to connect"
}

output "mongodb_password" {
  description = "Generated MongoDB password"
  value       = random_password.mongodb_password.result
  sensitive   = true
}

output "jwt_secret" {
  description = "Generated JWT secret"
  value       = random_password.jwt_secret.result
  sensitive   = true
}
