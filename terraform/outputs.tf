# Output the ARN of the SNS topic, which can be referenced by other modules or resources
output "sns_topic_arn" {
  value       = aws_sns_topic.ingestion_alerts.arn
}

# Output the name of the ingestion S3 bucket, which stores processed or raw ingestion data
output "s3_bucket_name" {
  value       = data.aws_s3_bucket.ingestion_bucket.bucket
}

# output "caller_identity" {
#   value = data.aws_caller_identity.current
# }

# output "region" {
#   value = data.aws_region.current
# }


# data "aws_caller_identity" "current" {}

# data "aws_region" "current" {}