resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.module_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when ${var.module_name} Lambda has > 0 errors."
  dimensions = {
    FunctionName = aws_lambda_function.ingestion.function_name
  }
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles_alarm" {
  alarm_name          = "${var.module_name}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when ${var.module_name} Lambda is throttled."
  dimensions = {
    FunctionName = aws_lambda_function.ingestion.function_name
  }
  alarm_actions       = [var.sns_topic]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_timeout_alarm" {
  alarm_name          = "${var.module_name}-lambda-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = 580  # 60s timeout set → alert if nearing limit
  alarm_description   = "Lambda ${var.module_name} duration too high (close to timeout)."
  dimensions = {
    FunctionName = aws_lambda_function.ingestion.function_name
  }
  alarm_actions       = [var.sns_topic]
  treat_missing_data  = "notBreaching"
}
