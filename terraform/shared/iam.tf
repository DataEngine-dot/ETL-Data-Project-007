# Get current AWS account info (used for resource ARNs)
data "aws_caller_identity" "current" {}

# Create IAM role for all Lambda functions (ingestion and transformation)
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_execution_role"

  # Allow Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for Lambda to write logs to CloudWatch
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
        # FIXED: Now allows logs for both ingestion and transformation lambdas!
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/lambda/ingestion-lambda*",
          "arn:aws:logs:*:*:log-group:/aws/lambda/transformation-lambda*",
          "arn:aws:logs:*:*:log-group:/aws/lambda/warehouse_loader-lambda*"
        ]
      }
    ]
  })
}

# Policy to allow Lambda to get secrets from Secrets Manager and publish SNS notifications
resource "aws_iam_policy" "lambda_secrets_sns_policy" {
  name = "LambdaSecretsAndSNSPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow reading DB secrets
      {
        Effect = "Allow",
        Action = ["secretsmanager:GetSecretValue"],
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:TotesysDatabase-*"
      },
      # Allow sending messages to the SNS topic for alerts/notifications
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = aws_sns_topic.ingestion_alerts.arn
      }
    ]
  })
}

# Policy to allow Lambda to write to and read from S3
resource "aws_iam_policy" "lambda_s3_write_policy" {
  name = "LambdaS3WritePolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/ingestion/*",
          "arn:aws:s3:::${var.bucket_name}/state/*",
          "arn:aws:s3:::${var.bucket_name}/transformation/*",
          "arn:aws:s3:::${var.bucket_name}/processed/*" 
        ]
      }
    ]
  })
}

# Attach log policy to role
resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# Attach secrets/SNS policy to role
resource "aws_iam_role_policy_attachment" "lambda_secrets_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secrets_sns_policy.arn
}

# Attach S3 read/write policy to role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_write_policy.arn
}
