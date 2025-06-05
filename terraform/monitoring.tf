# Define a CloudWatch Log Group to store logs from the ingestion Lambda function
# Retain logs for 14 days to allow sufficient time for debugging and monitoring
resource "aws_cloudwatch_log_group" "ingestion_logs" {
  name              = "/ingestion/application"
  retention_in_days = 14
}

# Create an SNS topic to publish ingestion-related alerts (e.g., errors, notifications)
resource "aws_sns_topic" "ingestion_alerts" {
  name = "ingestion-alerts"
}

# Subscribe an email address to the SNS topic to receive alerts in real time
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.ingestion_alerts.arn
  protocol  = "email"
  endpoint  = "deepjpt3@gmail.com"
}
