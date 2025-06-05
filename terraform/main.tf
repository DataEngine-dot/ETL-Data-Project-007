# # Generate a unique suffix for S3 bucket name if var.bucket_name is empty
# resource "random_id" "bucket_suffix" {
#   byte_length = 4

#   keepers = {
#     # Trigger regeneration only when no bucket name is provided
#     trigger = var.bucket_name == "" ? timestamp() : ""
#   }
# }

# Create the ingestion S3 bucket, using either a provided name or a unique one
resource "aws_s3_bucket" "ingestion_bucket" {
  bucket_prefix        = "ingestion-zone-extraction"
  force_destroy = true  # Allow deletion even if bucket contains objects
}
# Terraform can do this for you, and manage its state - use bucket_prefix attribute

# Define a bucket policy allowing Lambda, EventBridge, and CloudWatch Logs services access to S3
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowServicesAccess"
        Effect    = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "events.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.ingestion_bucket.arn}/*"
      }
    ]
  })
}
