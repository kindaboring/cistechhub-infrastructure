variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "Base name for S3 bucket (will be prefixed with environment)"
  type        = string
}
