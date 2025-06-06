# Upload the Lambda layer ZIP file to S3
resource "aws_s3_object" "all_deps_layer" {
  bucket = data.aws_s3_bucket.ingestion_bucket.id
  key    = "lambda-layer.zip"
  source = "../builds/lambda-layer.zip"
  etag   = filemd5("../builds/lambda-layer.zip")
}

#TODO: Create a local deployment package using a archive_file block https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
# Archive a single file.

data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/../ingestion.py"
  output_path = "${path.module}/../lambda_zip/ingestion.zip"
}
# https://docs.aws.amazon.com/lambda/latest/dg/python-package.html


# Register the uploaded Lambda layer in AWS
resource "aws_lambda_layer_version" "all_deps_layer" {
  layer_name          = "all-deps-layer"
  compatible_runtimes = ["python3.11"]
  s3_bucket           = data.aws_s3_bucket.ingestion_bucket.id
  s3_key              = aws_s3_object.all_deps_layer.key
  source_code_hash    = filebase64sha256("../builds/lambda-layer.zip")
}

# Define the Lambda function and its configuration
resource "aws_lambda_function" "ingestion" {
  function_name = "ingestion-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ingestion.main"
  runtime       = "python3.11"
  timeout       = 60
  filename      = data.archive_file.init.output_path
  # s3_bucket = aws_s3_bucket.ingestion_bucket.id
  # s3_key = data.archive_file.init.output_path #
#TODO filename = archive_file.output_path
# archive_file.output_base64sha256
  source_code_hash = data.archive_file.init.output_base64sha256
  publish = true

  environment {
    variables = {
      DB_HOST        = var.db_host
      DB_USER        = var.db_user
      DB_PASSWORD    = var.db_password
      S3_BUCKET      = data.aws_s3_bucket.ingestion_bucket.bucket
      SNS_TOPIC_ARN  = aws_sns_topic.ingestion_alerts.arn
      LOG_GROUP      = "/aws/lambda/ingestion-lambda"
    }
  }
        layers = [aws_lambda_layer_version.all_deps_layer.arn]

}


