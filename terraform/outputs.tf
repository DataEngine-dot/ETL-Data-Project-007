# Output the final S3 bucket name (custom or generated)
output "s3_bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.ingestion_bucket.bucket
}
