variable "db_host" {
  type = string
}

variable "db_port" {
  type = string
}

variable "db_user" {
  type = string
}


variable "db_password" {
  type      = string
  sensitive = true
}

variable "s3_bucket" {
  type = string
}

variable "sns_topic" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "module_name" {
  type    = string
  default = "ingestion"
}