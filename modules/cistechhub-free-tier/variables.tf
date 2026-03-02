variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH (use your IP for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP!
}

variable "uploads_bucket_name" {
  description = "S3 bucket name for auth uploads"
  type        = string
}

variable "uploads_bucket_arn" {
  description = "S3 bucket ARN for uploads"
  type        = string
}

variable "google_client_id" {
  description = "Google OAuth client ID (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth client secret (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_redirect_uri" {
  description = "Google OAuth redirect URI"
  type        = string
  default     = ""
}
