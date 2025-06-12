# ARN for the ingestion Lambda function
variable "ingestion_lambda_arn" {
  description = "ARN of the Ingestion Lambda function"
  type        = string
}

# ARN for the transformation Lambda function
variable "transformation_lambda_arn" {
  description = "ARN of the Transformation Lambda function"
  type        = string
}

# ARN for the warehouse loader Lambda function
variable "warehouse_loader_lambda_arn" {
  description = "ARN of the Warehouse Loader Lambda function"
  type        = string
}
