variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for MongoDB instance"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for MongoDB instance and EBS volume"
  type        = string
}

variable "app_server_sg_id" {
  description = "Security group ID of the application server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.medium"
}

variable "mongodb_version" {
  description = "MongoDB version to install"
  type        = string
  default     = "7.0"
}

variable "mongodb_volume_size" {
  description = "Size of EBS volume for MongoDB data (GB)"
  type        = number
  default     = 50
}

variable "db_username" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to MongoDB server"
  type        = list(string)
  default     = []
}
