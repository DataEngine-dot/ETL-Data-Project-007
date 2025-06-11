# Upload the Lambda deployment package to S3
resource "aws_s3_object" "lambda_zip" {
  bucket = var.s3_bucket
  key    = "ingestion-lambda.zip"
  source = "../../builds/ingestion-lambda.zip"
  etag   = filemd5("../../builds/ingestion-lambda.zip")
}

# Create the Lambda function
resource "aws_lambda_function" "ingestion" {
  function_name = "ingestion-lambda"
  role          = var.lambda_role_arn
  handler       = "ingestion.main"
  runtime       = "python3.11"
  timeout       = 60

  s3_bucket         = var.s3_bucket
  s3_key            = aws_s3_object.lambda_zip.key
  source_code_hash  = filebase64sha256("../../builds/ingestion-lambda.zip")

  environment {
    variables = {
      DB_HOST       = var.db_host
      DB_PORT       = var.db_port
      DB_USER       = var.db_user
      DB_PASSWORD   = var.db_password
      S3_BUCKET     = var.s3_bucket
      SNS_TOPIC_ARN = var.sns_topic
      LOG_GROUP     = "/aws/lambda/ingestion-lambda"
    }
  }
}

# EventBridge rule to run every 10 minutes
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "every-10-minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.ingestion.arn
}

# Permission for EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "ingestion_logs" {
  name              = "/aws/lambda/ingestion-lambda"
  retention_in_days = 14
}
