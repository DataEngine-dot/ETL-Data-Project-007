# Create the IAM role that Lambda assumes during execution
resource "aws_iam_role" "lambda_role" {
  name_prefix = "ingestion_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"  # Allow Lambda service to assume this role
        }
      }
    ]
  })
}

# Draft s3 policy document
data "aws_iam_policy_document" "s3_document" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.ingestion_bucket.arn}/*"]
    effect    = "Allow"
  }
}

# Draft CloudWatch policy document
data "aws_iam_policy_document" "cw_document" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
    effect    = "Allow"
  }
}

# Draft SNS policy document
data "aws_iam_policy_document" "sns_document" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.ingestion_alerts.arn]
    effect    = "Allow"
  }
}

# Draft secrets manager policy document
data "aws_iam_policy_document" "secretsmanager_document" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.db_secret.arn] # Wrap in list
    effect    = "Allow"
  }
}


# Attach the documents drafts to the policies
# Attach s3 document to the s3 policy
resource "aws_iam_policy" "s3_policy" {
    name_prefix = "s3-policy-${var.lambda_name}"
    policy = data.aws_iam_policy_document.s3_document.json
}

# Attach cw document to the cw policy
resource "aws_iam_policy" "cw_policy" {
    name_prefix = "cw-policy-${var.lambda_name}"
    policy = data.aws_iam_policy_document.cw_document.json
}

# Attach sns document to the sns policy
resource "aws_iam_policy" "sns_policy" {
    name_prefix = "sns-policy-${var.lambda_name}"
    policy = data.aws_iam_policy_document.sns_document.json
}

# Attach secretsmanager document to the secretsmanager policy
resource "aws_iam_policy" "secretsmanager_policy" {
    name_prefix = "secretsmanager-policy-${var.lambda_name}"
    policy = data.aws_iam_policy_document.secretsmanager_document.json
}

# Attach Policies to Role for Lambda 
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cw_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.cw_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sns_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secretmanager_policy_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.secretsmanager_policy.arn
}










# # Attach the AWS-managed policy for basic Lambda permissions (CloudWatch Logs, etc.)
# resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # Create a policy that grants full S3 access to the user running Terraform
# resource "aws_iam_policy" "s3_full_access" {
#   name        = "S3FullAccessForTerraformUsers"
#   description = "Full access to S3 for users running terraform apply"
#   policy      = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = [ "s3:*" ]    # Allow all S3 actions
#         Resource = "*"           # On all S3 resources
#       }
#     ]
#   })
# }

# # Attach the above full S3 access policy to the specific IAM user running Terraform
# resource "aws_iam_user_policy_attachment" "direct_s3_access" {
#   user       = "Test-Account"
#   policy_arn = aws_iam_policy.s3_full_access.arn
# }

# # Create a monitoring policy allowing CloudWatch Logs creation and SNS publishing
# resource "aws_iam_policy" "ingestion_monitoring_policy" {
#   name        = "IngestionMonitoringPolicy"
#   description = "Policy to allow CloudWatch logging and SNS publishing"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = "*"  # Allow log actions on all log groups
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "sns:Publish"
#         ],
#         Resource = aws_sns_topic.ingestion_alerts.arn  # Limit SNS access to this topic only
#       }
#     ]
#   })
# }

# # Attach the monitoring IAM policy to the Terraform user
# resource "aws_iam_user_policy_attachment" "attach_ingestion_monitoring" {
#   user       = "Test-Account"
#   policy_arn = aws_iam_policy.ingestion_monitoring_policy.arn
# }
# # Define a policy for Lambda to access Secrets Manager and publish to SNS
# resource "aws_iam_policy" "lambda_secrets_sns_policy" {
#   name        = "LambdaSecretsAndSNSPolicy"
#   description = "Allow Lambda to get secrets and publish SNS messages"
#   policy      = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Resource = "arn:aws:secretsmanager:eu-west-2:645583760702:secret:TotesysDatabase*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "sns:Publish"
#         ]
#         Resource = "arn:aws:sns:eu-west-2:645583760702:ingestion-alerts"
#       }
#     ]
#   })
# }
# # Attach the secrets + SNS policy to the Lambda execution role
# resource "aws_iam_role_policy_attachment" "lambda_attach_policy" {
#   role       = aws_iam_role.lambda_exec.name 
#   policy_arn = aws_iam_policy.lambda_secrets_sns_policy.arn
# }
# # Policy to allow Lambda to write to a specific S3 bucket
# resource "aws_iam_policy" "lambda_s3_write_policy" {
#   name        = "LambdaS3WritePolicy"
#   description = "Allow Lambda to write objects to dynamic ingestion S3 bucket"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:PutObject",
#           "s3:GetObject"
#         ],
#         Resource = "arn:aws:s3:::${var.bucket_name}/*"
#       }
#     ]
#   })
# }
# # Attach the above S3 write policy to the Lambda execution role
# resource "aws_iam_role_policy_attachment" "lambda_attach_s3_write" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = aws_iam_policy.lambda_s3_write_policy.arn
# }
# # Policy to allow Lambda to write to any data-ingestion bucket (wildcard)
# resource "aws_iam_policy" "lambda_s3_dynamic_write_policy" {
#   name        = "LambdaS3DynamicWritePolicy"
#   description = "Allow Lambda to write to any data-ingestion S3 bucket"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:PutObject"
#         ],
#         Resource = "arn:aws:s3:::data-ingestion-bucket-*/*"
#       }
#     ]
#   })
# }
# # Attach dynamic bucket access policy to Lambda
# resource "aws_iam_role_policy_attachment" "lambda_attach_s3_dynamic_write" {
#   role       = aws_iam_role.lambda_exec.name
#   policy_arn = aws_iam_policy.lambda_s3_dynamic_write_policy.arn
# }
