# Get current AWS account ID for unique bucket naming
data "aws_caller_identity" "current" {}

# S3 Bucket for Auth Service Uploads
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.environment}-cistechhub-uploads-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.environment}-cistechhub-uploads"
    Application = "cistechhub"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption (free tier compatible)
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Free tier compatible
    }
  }
}

# S3 Bucket Public Access Block (security best practice)
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Rule to manage storage costs
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "cleanup-old-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Delete files older than 90 days (adjust as needed)
    expiration {
      days = 90
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS configuration for uploads from web application
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
