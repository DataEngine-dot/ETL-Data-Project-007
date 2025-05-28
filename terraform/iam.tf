resource "aws_iam_policy" "extraction_cloud_watch_policy" {
  name        = "extraction-cloudwatch-policy"
  description = "Allows CloudWatch logging and metric access for data extraction"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["cloudwatch:*","logs:*"]
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "policy"{
   statement {
    effect = "Allow"
    resources = ["*"]
   } 
}

resource "aws_iam_user_policy_attachment" "attach_extraction_cloudwatch_policy"{
    user = "test-account"
    policy_arn = aws_iam_policy.extraction_cloud_watch_policy.arn
}