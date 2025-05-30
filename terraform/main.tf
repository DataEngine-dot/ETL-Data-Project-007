# Generate a unique suffix if no bucket name is provided
resource "random_id" "bucket_suffix" {
  byte_length = 4

  # Force regeneration if bucket_name is not set
  # If bucket_name is empty, we trigger new ID each run
  keepers = {
    trigger = var.bucket_name == "" ? timestamp() : ""
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "ingestion_bucket" {
  # If bucket_name is provided, use it. Otherwise, construct a unique name.
  bucket = var.bucket_name != "" ? var.bucket_name : "data-ingestion-bucket-${random_id.bucket_suffix.hex}"

  force_destroy = true # Allows deleting bucket even if it contains objects
}

# Add a bucket policy that allows Lambda, CloudWatch, EventBridge access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.ingestion_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowServicesAccess",
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "events.amazonaws.com",
            "logs.amazonaws.com"
          ]
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.ingestion_bucket.arn}/*"
      }
    ]
  })
}
