output "uploads_bucket_id" {
  description = "ID of the uploads bucket"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "ARN of the uploads bucket"
  value       = aws_s3_bucket.uploads.arn
}

output "uploads_bucket_name" {
  description = "Name of the uploads bucket"
  value       = aws_s3_bucket.uploads.bucket
}

output "uploads_bucket_region" {
  description = "Region of the uploads bucket"
  value       = aws_s3_bucket.uploads.region
}
