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
  description = "Public subnet ID for application server"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB target group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to application server"
  type        = list(string)
  default     = []
}

variable "mongodb_host" {
  description = "MongoDB host address"
  type        = string
}

variable "uploads_bucket_name" {
  description = "S3 bucket name for uploads"
  type        = string
}

variable "uploads_bucket_arn" {
  description = "S3 bucket ARN for uploads"
  type        = string
}

variable "secrets_policy_arn" {
  description = "ARN of secrets access IAM policy"
  type        = string
}
