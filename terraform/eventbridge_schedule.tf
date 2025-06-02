# Create a CloudWatch Event Rule that triggers every 10 minutes
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "every-10-minutes"
  schedule_expression = "rate(10 minutes)"

# 1) To remove the Event Rule from Terraform, you must manually delete its Target in AWS Console:
  #    AWS Console → EventBridge → Rules → every-10-minutes → Remove all associated Targets
  #    Then rerun `terraform apply` — Terraform will be able to delete the rule.

  # 2) If Terraform does not update the rule after changing the schedule_expression,
  #    it may be due to a known AWS bug or cached state. You can force replacement with:
  #    terraform apply -replace=aws_cloudwatch_event_rule.lambda_schedule
}

# Set the Lambda function as a target for the EventBridge rule above
resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.ingestion.arn
}

# Allow EventBridge to invoke the Lambda function by attaching necessary permission
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

# Create a custom IAM policy allowing the Lambda to write logs to CloudWatch
resource "aws_iam_policy" "lambda_logging" {
  name = "lambda-logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/ingestion-lambda*"
      }
    ]
  })
}
# Attach the logging policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

