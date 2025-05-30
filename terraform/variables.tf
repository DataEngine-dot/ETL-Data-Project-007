# Optional custom bucket name
variable "bucket_name" {
  description = "Optional S3 bucket name. If not provided, a unique name will be generated"
  type        = string
  default     = ""
}
