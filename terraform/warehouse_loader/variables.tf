variable "warehouse_db_host" {
  type = string
}

variable "warehouse_db_name" {
  type = string
}

variable "warehouse_db_port" {
  type = string
}

variable "warehouse_db_user" {
  type = string
}

variable "warehouse_db_password" {
  type = string
}

variable "sns_topic" {
  type = string
}

variable "s3_bucket" {
  description = "S3 bucket for the warehouse loader"
  type        = string
}

variable "lambda_role_arn" {
  type = string
  description = "IAM Role ARN for Lambda execution"
}

