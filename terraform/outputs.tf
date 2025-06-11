output "s3_bucket_name" {
  value = module.shared.ingestion_bucket
}

output "sns_topic_arn" {
  value = module.shared.sns_topic
}
