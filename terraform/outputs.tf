# Output the ARN of the SNS topic, which can be referenced by other modules or resources
output "sns_topic_arn" {
  value       = aws_sns_topic.ingestion_alerts.arn
}

# Output the name of the ingestion S3 bucket, which stores processed or raw ingestion data
output "s3_bucket_name" {
  value       = aws_s3_bucket.ingestion_bucket.bucket
}
