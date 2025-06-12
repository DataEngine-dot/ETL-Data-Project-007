output "lambda_error_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.lambda_error_alarm.arn
}

output "lambda_arn" {
  value = aws_lambda_function.ingestion.arn
}