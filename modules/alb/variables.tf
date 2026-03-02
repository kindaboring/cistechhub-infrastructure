variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (leave empty to use HTTP only)"
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Enable AWS WAF for the ALB"
  type        = bool
  default     = true
}
