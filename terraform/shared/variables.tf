variable "bucket_name" {
  type = string
}

variable "alert_email" {
  description = "Email address to receive alarm notifications"
  type        = string
}

variable "aws_region" {
  default = "eu-west-2"
}