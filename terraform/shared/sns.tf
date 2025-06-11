resource "aws_sns_topic" "ingestion_alerts" {
  name = "ingestion-alerts"
}

output "sns_topic" {
  value = aws_sns_topic.ingestion_alerts.arn
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.ingestion_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
