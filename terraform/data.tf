data "aws_secretsmanager_secret" "db_secret" {
  name = "TotesysDatabase" 
}

# data "aws_sns_topic" "ingestion_alerts" {
#   name = data.aws_sns_topic.ingestion_alerts.name
# }

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


data "aws_s3_bucket" "ingestion_bucket" {
  bucket = "ingestion-bucket-zone-etl-project"
}

# ${data.aws_secretsmanager_secret.db_secret.arn} -> refer to the secretsmanager and get the arn


# ${data.aws_sns_topic.ingestion_alerts.arn}
