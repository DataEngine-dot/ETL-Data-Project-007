resource "aws_lambda_function" "warehouse_loader" {
  function_name = "warehouse_loader-lambda"
  role          = var.lambda_role_arn
  handler       = "warehouse_loader.handler"
  runtime       = "python3.11"
  timeout       = 60

  s3_bucket         = var.s3_bucket
  s3_key            = "builds/warehouse_loader-lambda.zip"
  source_code_hash  = filebase64sha256("../../builds/warehouse_loader-lambda.zip") # Make sure the zip exists

  environment {
    variables = {
      WAREHOUSE_DB_HOST       = var.warehouse_db_host
      WAREHOUSE_DB_NAME       = var.warehouse_db_name
      WAREHOUSE_DB_PORT       = var.warehouse_db_port
      WAREHOUSE_DB_USER       = var.warehouse_db_user
      WAREHOUSE_DB_PASSWORD   = var.warehouse_db_password
      S3_BUCKET     = var.s3_bucket
      SNS_TOPIC_ARN = var.sns_topic
      LOG_GROUP = "/aws/lambda/warehouse_loader-lambda"
    }
  }
}

resource "aws_cloudwatch_log_group" "warehouse_loader_logs" {
  name              = "/aws/lambda/warehouse_loader-lambda"
  retention_in_days = 14
}