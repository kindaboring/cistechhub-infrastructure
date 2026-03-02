variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "mongodb_username" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
}

variable "mongodb_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
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
