output "instance_id" {
  description = "ID of the MongoDB instance"
  value       = aws_instance.mongodb.id
}

output "private_ip" {
  description = "Private IP address of MongoDB instance"
  value       = aws_instance.mongodb.private_ip
}

output "security_group_id" {
  description = "Security group ID of MongoDB instance"
  value       = aws_security_group.mongodb.id
}

output "mongodb_uri" {
  description = "MongoDB connection URI (internal)"
  value       = "mongodb://${aws_instance.mongodb.private_ip}:27017"
  sensitive   = true
}
