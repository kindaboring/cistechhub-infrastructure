output "application_url" {
  description = "URL to access the cistechhub application"
  value       = module.cistechhub.application_url
}

output "public_ip" {
  description = "Public IP address of the application server"
  value       = module.cistechhub.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = module.cistechhub.ssh_command
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.cistechhub.instance_id
}

output "uploads_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = module.storage.uploads_bucket_name
}

output "mongodb_password" {
  description = "Generated MongoDB password (store securely!)"
  value       = module.cistechhub.mongodb_password
  sensitive   = true
}

output "jwt_secret" {
  description = "Generated JWT secret (store securely!)"
  value       = module.cistechhub.jwt_secret
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT

  ========================================
  🎉 Cistechhub AWS Migration Complete!
  ========================================

  Your application is being deployed to: ${module.cistechhub.application_url}

  IMPORTANT: It may take 5-10 minutes for the application to be fully available
  after Terraform completes, as Docker images need to be pulled and services started.

  📋 Next Steps:

  1. Wait for deployment to complete:
     Watch the deployment: ${module.cistechhub.ssh_command}
     Then run: sudo tail -f /var/log/user-data.log

  2. Access your application:
     Open in browser: ${module.cistechhub.application_url}

  3. View sensitive credentials:
     terraform output mongodb_password
     terraform output jwt_secret

  4. Check application logs:
     SSH to server and run:
     cd /opt/cistechhub && docker-compose logs -f

  5. Security Recommendations:
     - Update ssh_allowed_cidrs in terraform.tfvars to your IP only
     - Consider setting up a domain with Route 53
     - Add SSL certificate with ACM when you have a domain

  💰 Cost Monitoring:
     - This setup uses FREE TIER resources
     - Monitor your AWS Free Tier usage in AWS Console
     - Main costs: None if within free tier limits

  🔧 Useful Commands:
     - Restart services: cd /opt/cistechhub && sudo docker-compose restart
     - View logs: cd /opt/cistechhub && sudo docker-compose logs -f
     - Stop all: cd /opt/cistechhub && sudo docker-compose down
     - Start all: cd /opt/cistechhub && sudo docker-compose up -d

  ========================================
  EOT
}
