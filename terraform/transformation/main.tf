# Upload the Lambda deployment package to S3
resource "aws_s3_object" "lambda_zip" {
  bucket = var.input_bucket                # Use the same bucket as in Makefile and variables
  key    = "builds/transformation-lambda.zip"
  source = "../../builds/transformation-lambda.zip"
  etag   = filemd5("../../builds/transformation-lambda.zip")
}

# Create the Lambda function using the uploaded zip
resource "aws_lambda_function" "transformation" {
  function_name     = "transformation-lambda"
  role              = var.lambda_role_arn
  handler           = "transformation.handler"
  runtime           = "python3.11"
  timeout           = 60

  s3_bucket         = var.input_bucket
  s3_key            = aws_s3_object.lambda_zip.key
  source_code_hash  = filebase64sha256("../../builds/transformation-lambda.zip")

  environment {
    variables = {
      INPUT_BUCKET   = var.input_bucket
      OUTPUT_BUCKET  = var.output_bucket
      SNS_TOPIC_ARN  = var.sns_topic
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "transformation-every-10-minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.transformation.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transformation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}