output "web_server_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web_server.id
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_sg_id" {
  description = "Security group ID of the web server"
  value       = aws_security_group.web_server.id
}
