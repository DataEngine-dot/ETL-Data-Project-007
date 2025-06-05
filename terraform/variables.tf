# Optional S3 bucket name. If empty, a unique bucket name will be generated
variable "bucket_name" {
  type        = string
  default     = ""
}

# Variable for the hostname or endpoint of the source database (e.g., RDS or external DB)
variable "db_host" {
  type        = string
}

# Variable for the username used to connect to the source database
variable "db_user" {
  type        = string
}

# Sensitive variable for the database password (hidden in plan/apply output)
variable "db_password" {
  type        = string
  sensitive   = true
}

# Variable representing the S3 bucket name where ingestion output files are written
variable "s3_ingestion_bucket" {
  type        = string
}

variable "lambda_name" {
    type = string
    default = "ingestion-lambda"
}