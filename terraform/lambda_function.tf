# Upload the Lambda layer ZIP file to S3
resource "aws_s3_object" "all_deps_layer" {
  bucket = aws_s3_bucket.ingestion_bucket.id
  key    = "lambda-layer.zip"
  source = "../builds/lambda-layer.zip"
  etag   = filemd5("../builds/lambda-layer.zip")
}
# Register the uploaded Lambda layer in AWS
resource "aws_lambda_layer_version" "all_deps_layer" {
  layer_name          = "all-deps-layer"
  compatible_runtimes = ["python3.11"]
  s3_bucket           = aws_s3_bucket.ingestion_bucket.id
  s3_key              = aws_s3_object.all_deps_layer.key
  source_code_hash    = filebase64sha256("../builds/lambda-layer.zip")
}
# Upload the Lambda deployment package (ZIP) to S3
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.ingestion_bucket.id          
  key    = "ingestion-lambda.zip"               
  source = "../builds/ingestion-lambda.zip"
  etag   = filemd5("../builds/ingestion-lambda.zip")
}
# Define the Lambda function and its configuration
resource "aws_lambda_function" "ingestion" {
  function_name = "ingestion-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "ingestion.main"
  runtime       = "python3.11"
  timeout       = 60

  s3_bucket = aws_s3_bucket.ingestion_bucket.id
  s3_key    = aws_s3_object.lambda_zip.key

  source_code_hash = filebase64sha256("../builds/ingestion-lambda.zip")
  publish = true

  environment {
    variables = {
      DB_HOST        = var.db_host
      DB_USER        = var.db_user
      DB_PASSWORD    = var.db_password
      S3_BUCKET      = aws_s3_bucket.ingestion_bucket.bucket
      SNS_TOPIC_ARN  = aws_sns_topic.ingestion_alerts.arn
      LOG_GROUP      = "/aws/lambda/ingestion-lambda"
    }
  }
        layers = [aws_lambda_layer_version.all_deps_layer.arn]

}


