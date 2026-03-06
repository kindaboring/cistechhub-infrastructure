variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"  # Free tier available in all regions, us-east-1 is common
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# Compute Variables
variable "instance_type" {
  description = "EC2 instance type (use t3.micro for free tier)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (create one in AWS console first)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to the server (use your IP for security)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # IMPORTANT: Change this to your IP address!
}

# Application Variables
variable "google_client_id" {
  description = "Google OAuth client ID (optional, for Google sign-in)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth client secret (optional, for Google sign-in)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_redirect_uri" {
  description = "Google OAuth redirect URI"
  type        = string
  default     = ""
}
