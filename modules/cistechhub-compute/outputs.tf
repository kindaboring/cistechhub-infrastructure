output "instance_id" {
  description = "ID of the application server instance"
  value       = aws_instance.app_server.id
}

output "public_ip" {
  description = "Public IP address (Elastic IP)"
  value       = aws_eip.app_server.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.app_server.private_ip
}

output "security_group_id" {
  description = "Security group ID of application server"
  value       = aws_security_group.app_server.id
}
