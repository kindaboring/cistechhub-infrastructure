variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "allowed_origins" {
  description = "Allowed origins for CORS (application URLs)"
  type        = list(string)
  default     = ["*"]
}
